import os
import re
import json
from dotenv import load_dotenv
import fitz  # PyMuPDF
from langchain.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI
import pytesseract
from pdf2image import convert_from_path
from PIL import Image

# Set Tesseract path (Windows only)
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

# Load environment variables
load_dotenv()

# Set up base path relative to this script
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(BASE_DIR))

INPUT_FOLDER = os.path.join(PROJECT_ROOT, "assets", "journals_conference_papers")
OUTPUT_FOLDER = os.path.join(PROJECT_ROOT, "assets", "extracted_journals_conference_papers")

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

# -------------------------------
# ✨ Helper Function for Citation Formatting
# -------------------------------

def format_citation(title, authors, journal, year):
    """
    Formats the citation into a structured dictionary.
    """
    return {
        "title": title or "Untitled",
        "authors": [author.strip() for author in authors if author.strip()],
        "journal": journal or "",
        "year": year or "",
        "source": "guessed"
    }

# -------------------------------
# 🔍 Smart PDF Extraction
# -------------------------------

def extract_pdf_content(pdf_path):
    """Extract text and guess citation data from digital PDF"""
    doc = fitz.open(pdf_path)
    full_text = ""
    for page in doc:
        full_text += page.get_text()

    lines = full_text.split('\n')[:200]  # look at first 200 lines

    title = None
    authors = []
    journal = None
    year = None

    # Try to find title
    for line in lines[:20]:
        if len(line.strip()) > 30 and not any(char.isdigit() for char in line[:5]):
            title = line.strip()
            break

    # Try to find authors
    for i, line in enumerate(lines[:50]):
        if re.search(r"(Author[s]?|Authors?:)", line, re.IGNORECASE):
            next_line = lines[i+1] if i+1 < len(lines) else ""
            authors.append(next_line.strip())

    # Try to find journal name
    for line in lines[:100]:
        if re.search(r"(Published|Journal|DOI|Institute|University)", line, re.IGNORECASE):
            journal = line.strip()
            break

    # Try to find year
    for line in lines[:100]:
        match = re.search(r"\b(19[0-9]{2}|20[0-9]{2})\b", line)
        if match:
            year = match.group(0)
            break

    return {
        "text": full_text,
        "citation": format_citation(title, authors, journal, year)
    }

# -------------------------------
# 🖼 OCR-Based Extraction
# -------------------------------

def extract_with_ocr(pdf_path):
    """
    Extracts text from a scanned PDF using OCR.
    Returns a dictionary with full text and empty citation info.
    """
    print(f"⚠️ Falling back to OCR for {os.path.basename(pdf_path)}")
    
    try:
        # Specify Poppler path explicitly
        poppler_path = r"C:\path\to\poppler\bin"  # Update this path to your Poppler installation
        images = convert_from_path(pdf_path, dpi=200, first_page=0, last_page=3, poppler_path=poppler_path)
        
        full_text = ""
        for i, image in enumerate(images):
            print(f"⏳ Running OCR on page {i+1}...")
            full_text += "\n\n--- PAGE {} ---\n\n".format(i+1)
            full_text += pytesseract.image_to_string(image)

        return {
            "text": full_text,
            "citation": format_citation(None, [], None, None)
        }

    except Exception as e:
        print(f"❌ OCR extraction failed: {e}")
        return {
            "text": "",
            "citation": format_citation(None, [], None, None)
        }

# -------------------------------
# 🧾 LLM Processing
# -------------------------------

def summarize_with_llm(text, concept_name, citation):
    prompt_template = ChatPromptTemplate.from_template(
        """
You are a therapist and science communicator writing for teens and young adults who are new to emotional awareness.
Your task is to create an accessible explanation of the research paper excerpt about "{concept_name}".

Instructions:
1. Use SIMPLE LANGUAGE that everyone can understand. Avoid technical jargon and complex terms.
2. Structure your response as JSON with the following fields: "title", "friendly_definition", "real_life_example", "often_confused_with", "research_insight", "personal_check_in".
3. Ensure the "title" is SHORT, CLEAR, and WRITTEN IN EVERYDAY LANGUAGE.
4. Keep your response in JSON format only. Strictly your response in less than 150 words, only answer the 6 sub-questions.


Fields to Fill:
- Title: A simple, engaging title summarizing the emotion in everyday terms (max 8 words).
- Friendly Definition: What is {concept_name} in everyday language? How does it feel in your body and mind?
- Real-Life Example: Share one situation where teens or young adults might experience this emotion.
- Often Confused With: How might people misunderstand this feeling or mistake it for something else?
- Research Insight: Share one key finding from the paper that helps understand this emotion, explained simply.
- Personal Check-In: Offer a thoughtful question that helps someone recognize and reflect on this in their own life.

Excerpt:
{text}

Citation:
{citation}
        """
    )

    model = ChatOpenAI(model="gpt-3.5-turbo", temperature=0.3, openai_api_key=OPENAI_API_KEY)
    prompt = prompt_template.format_prompt(concept_name=concept_name, text=text[:6000], citation=json.dumps(citation))
    response = model.invoke(prompt.to_messages())

    try:
        summary = json.loads(response.content)
        summary["citation"] = citation
        return summary
    except Exception as e:
        print(f"Error parsing LLM response: {e}")
        return {"raw": response.content, "citation": citation}

# -------------------------------
# 📁 Main Function
# -------------------------------

def process_all_pdfs(input_folder, output_folder):
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    for filename in os.listdir(input_folder):
        if filename.lower().endswith(".pdf"):
            pdf_path = os.path.join(input_folder, filename)
            concept_name = " ".join(filename.replace(".pdf", "").split("_")[1:]).title()

            print(f"\n📄 Processing: {filename} | Concept: {concept_name}")

            # Try primary extraction
            try:
                content = extract_pdf_content(pdf_path)
                if len(content["text"].strip()) < 100:
                    print("⚠️ Low-quality text detected. Falling back to OCR...")
                    content = extract_with_ocr(pdf_path)
            except Exception as e:
                print(f"❌ Primary extraction failed: {e}. Trying OCR fallback...")
                content = extract_with_ocr(pdf_path)

            raw_text = content["text"]
            citation = content["citation"]

            if raw_text.strip():
                summary = summarize_with_llm(raw_text, concept_name, citation)

                output_file = os.path.join(output_folder, f"{os.path.splitext(filename)[0]}_summary.json")
                with open(output_file, "w", encoding="utf-8") as f:
                    json.dump(summary, f, indent=4)

                print(f"📝 Saved summary to: {output_file}")
            else:
                print("❌ No text extracted. Skipping summarization.")

# -------------------------------
# 🚀 Run the Pipeline
# -------------------------------

if __name__ == "__main__":
    process_all_pdfs(INPUT_FOLDER, OUTPUT_FOLDER)