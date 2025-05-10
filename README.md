# 🧠 Emotional Wellness Journal App

> A data-driven emotional journaling platform powered by AI, designed to enhance therapy through real-time emotional tracking, personalized insights, and child-friendly engagement tools.

## 📌 Overview

The **Emotional Wellness Journal App** addresses critical shortcomings in the mental health and wellness industry by combining **AI-powered emotion analysis**, **interactive journaling**, and **therapy-enhancing visualization tools**. It supports therapists with structured patient insights, automates progress tracking, and encourages daily emotional reflection — especially for children who may struggle with traditional journaling methods.

This app bridges the gap between session-based therapy and everyday emotional awareness, offering a scalable solution for both individual users and clinical environments.

---

## 🔍 Core Features

### 1. **AI-Driven Emotional Analysis**

- Utilizes a **Mixture-of-Experts (MoE)** architecture to dynamically select the most appropriate LLM based on user input.
- Models are fine-tuned for:
  - **Anxiety**
  - **Depression**
  - **ADHD**
- Provides qualitative and quantitative assessments of emotional states using prompts like:
  > "Rate this entry on sadness from 1–10"
- Supports multi-modal inputs (text, voice) for accessibility.

> 💡 For future improvements, consider including model accuracy benchmarks and training methodology in `/docs/models.md`.

---

### 2. **Automated Note-Taking & Structured Logging**

- Replaces manual note-taking with intelligent logging that captures key emotional themes, triggers, and progress markers.
- Ensures consistency across sessions for longitudinal trend analysis.
- Notes are tagged and stored in a searchable database for therapist review.

> 💡  Add metadata tagging (e.g., mood, context, session number) for advanced filtering and analytics.

---

### 3. **Emotional Trend Visualization**

- Visualizes patterns over time using interactive charts:
  - Time-series graphs
  - Mood wheels
  - Hexagonal radar plots *(based on [Stack Overflow example](https://stackoverflow.com/questions/65726076/plotting-data-on-a-hexagonal-figure ))*
- Helps identify recurring emotional states, triggers, and treatment effectiveness.

> 💡 Consider integrating animated visualizations for better temporal storytelling and therapist presentations.

---

### 4. **Interactive Chatbot Interface for Children**

- Designed to guide children through daily emotional check-ins using a conversational interface.
- Encourages habit formation through gamified prompts and feedback.
- Helps children articulate emotions they may not yet have the vocabulary for.

> 💡 Add optional avatars or story-based interactions to increase engagement.

---

### 5. **Parental & Therapist Dashboard**

- Real-time dashboards for monitoring emotional trends and progress.
- Includes alerts for significant emotional shifts or recurring issues.
- Enables therapists to update care plans based on data-backed insights.

> 💡 Allow export of visual reports in PDF/CSV for sharing with schools or healthcare providers.

---

### 6. **RAG-Based Resource Library**

- Leverages **Retrieval-Augmented Generation (RAG)** to provide evidence-based advice and guidance:
  - Parenting strategies for emotional regulation
  - How to support children with depression or ADHD
  - Communication techniques for educators and managers
- Content sourced from peer-reviewed journals, parenting guides, and psychological research.
- Embeddings enable fast retrieval of relevant resources based on user context.

> 💡  Cite sources directly in UI and allow filtering by source credibility (e.g., peer-reviewed vs. blog).

---

### 7. **LLM Evaluation Framework**

- Uses prompt-based evaluations to assess emotional content:
  - Rating systems (e.g., sadness, anxiety levels)
  - Comparison against historical logs
  - Sentiment and tone detection
- Integrates modern evaluation methodologies (as of 2024) to ensure high-quality outputs.

> 💡 Implement inter-rater reliability checks or use human-in-the-loop validation for sensitive cases.

---

## 🛠️ Technology Stack

| Layer        | Tools & Technologies                          |
|-------------|-----------------------------------------------|
| Frontend     | Flutter                                      |
| Backend      | Node.js                                       |
| Database     | Firebase                                     |
| AI Models    | HuggingFace Transformers / fine-tuned LLMs   |
| RAG System   | LangChain + Pinecone / FAISS                  |
| Visualization| D3.js / Plotly                                |

> 💡 *Tip*: Provide a tech diagram in `/docs/architecture.md` to show system flow and data pipelines.

---

## 📚 References & Inspirations

- [Hexagon chart visualization – Stack Overflow](https://stackoverflow.com/questions/65726076/plotting-data-on-a-hexagonal-figure )
- Emotion classification papers from ACL, NeurIPS, and EMNLP
- Child psychology guidelines from APA and CDC
- Open-source mental health datasets (e.g., RECOLA, DAIC-WOZ)

> 💡 *Tip*: Create a `/papers` folder with summaries and citations for reproducibility and academic alignment.

---

## 📈 Future Roadmap

- Voice journaling and speech-to-text integration
- Wearable device sync (heart rate, sleep patterns)
- Gamification: rewards, streaks, mood maps
- Multi-user support for group/family therapy
- Integration with school/clinic systems (FHIR compliance?)

---
