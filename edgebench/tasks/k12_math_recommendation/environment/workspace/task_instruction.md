## Title

K12 Math Knowledge Tracing & Personalized Question Recommendation

## Task Requirements

You are a core engineer on the algorithm team of a leading K12 online education platform (over 5 million registered students, covering middle and high school math nationwide). You are responsible for building a "Personalized Practice Engine." Current business pain points:

Background: The platform's current practice module uses a coarse-grained "practice questions in knowledge-point order" strategy, leading to two problems:

1. High-achieving students repeatedly practice already-mastered content, resulting in low time efficiency;

2. Struggling students are served overly difficult questions, causing repeated frustration, poor learning experience, and high dropout rates.

   The instructional design and product teams want the algorithm team to build a "Knowledge Tracing + Personalized Recommendation" system that dynamically models each student's knowledge mastery state based on their answer history, and recommends the most suitable practice questions, improving learning efficiency while controlling frustration.


Task objective: Based on provided student answer logs, question bank, and knowledge point graph, build a personalized practice engine. During evaluation, the system must output the following three items for a set of "test student × recommendation time" scenarios:

1. Knowledge state prediction: For a given student at a given time, predict their mastery probability (0~1) across 50 target knowledge points.

2. Next-question answer prediction: For a given student's N candidate questions to answer next, predict the probability of answering each correctly (0~1).

3. Recommended question sequence: For each test student, recommend the next 10 questions to answer (selected from a candidate pool of 200, output as an ordered list of question IDs).

   

   Optimization objectives (in priority order):

4. Next-question answer prediction AUC (most important): Accurately predicting whether a student will answer the next question correctly or incorrectly is the foundation of the entire system.

5. Knowledge mastery probability calibration: Predicted mastery probabilities should match real proficiency levels (e.g., a knowledge point predicted at 0.7 should have an actual correct rate close to 0.7).

6. Recommendation sequence learning gain: After the recommended 10 questions are simulated through the evaluator's built-in student simulator, the student's score improvement on a "post-test" should be as large as possible.

7. Recommendation constraint satisfaction rate: The recommended sequence must satisfy instructional design constraints — progressive difficulty (difficulty gap between consecutive questions ≤ 1 level), priority coverage of weak knowledge points, no re-recommendation of questions done in the past 7 days, respecting prerequisite relationships (do not recommend questions whose prerequisites are not yet mastered).


Provided data and materials:

- answering_logs.csv: Training answer logs, approximately 800,000 interaction records. Fields include student_id / question_id / knowledge_point_ids / timestamp / is_correct / time_spent_sec / response.
- question_bank.csv: Question bank with 5,000 questions. Fields include question_id / difficulty_level (1~5) / knowledge_point_ids / question_type / avg_correct_rate / discrimination.
- knowledge_graph.csv: Knowledge point graph with 50 core high school math knowledge points. Fields: kp_id / kp_name / chapter / prerequisite_kp_ids (prerequisite relationships).
- student_info.csv: Student profiles. Fields: student_id / grade / entry_test_score / region_tier.
- knowledge_point_taxonomy.md: Knowledge point hierarchy description and typical error types.
- dev_scenarios.json: Development set with 100 "student × time" scenarios for self-testing and tuning.
- output_schema.json: Example JSON structure for submission results.




Constraints:

1. Inference time: ≤ 2 seconds per scenario, ≤ 200 seconds total for 100 evaluation scenarios;
2. Total model training time ≤ 6 hours (CPU environment);
3. The system must be reproducible: provide complete training script train.py and inference script infer.py. Running `python infer.py --scenarios test_scenarios.json --output submission.json` must produce the submission file;
4. Data usage boundary (replacing the original "do not use test student_id" wording): Test scenario student IDs and their answer history before cutoff are included in the provided answering_logs.csv and may be used during the training phase — this is fundamental to knowledge tracing. However, the following are prohibited:
   - Using any answer data after a test scenario's cutoff_ts (i.e., "future answers")
   - Using the specific content of test_scenarios.json / test_ground_truth.json for any hyperparameter selection, early stopping, or model ensemble weight adjustment
   - Accessing any answer data after cutoff_ts during inference
     The evaluation script will split history by scenario cutoff_ts; the reference baseline train.py only does data pre-aggregation (no learning involved), and during inference explicitly bisects history, complying with the above boundaries.




Final deliverables (place in the submission root directory):

- train.py: Training script that reads answering_logs.csv and other inputs; if the solution requires training a model or pre-computing indices, write inference artifacts to the ./models/ directory under the submission root;
- infer.py: Inference script that reads a scenario file and produces submission.json; during evaluation, infer.py will be run directly — train.py will NOT be run automatically before evaluation, so models, indices, calibrators, etc. required by infer.py must be included in ./models/;
- models/: Optional directory; required when infer.py needs to load training artifacts. May contain .pkl / .joblib / .json / .npz / .txt and other custom model or preprocessing files;

During evaluation, submitted files will be placed under /home/workspace: infer.py at /home/workspace/infer.py, models/ at /home/workspace/models/. When loading models, indices, configurations, etc., infer.py should use relative paths like ./models/... or Path(__file__).resolve().parent / "models" / ...; do not rely on absolute paths from local development machines, training containers, or temporary directories.

- submission.json: Development set results produced on the provided dev_scenarios.json (for self-testing);
- requirements.txt: Dependency list;
- README.md: Method description (briefly describe approach and design rationale; not scored for quality).



The evaluator will use an undisclosed test_scenarios.json (containing 100 evaluation scenarios + corresponding real subsequent answers + post-test questions) to run your infer.py, and compute the final score according to the scoring formula described below.

## Task Input Description

In addition to the task requirements above, input data and materials are located in the `attachments/` directory:

| File | Format | Description | Relative Path |
| --- | --- | --- | --- |
| answering_logs.csv | CSV, ~800K rows | Student answer training logs, chronologically ordered | `attachments/input_data/answering_logs.csv` |
| question_bank.csv | CSV, 5000 rows | Question bank basic info and statistical features | `attachments/input_data/question_bank.csv` |
| knowledge_graph.csv | CSV, 50 rows | Knowledge point graph with prerequisite relationships | `attachments/input_data/knowledge_graph.csv` |
| student_info.csv | CSV, 10K students | Student profile base data | `attachments/input_data/student_info.csv` |
| knowledge_point_taxonomy.md | Markdown | Knowledge point descriptions and typical error types | `attachments/input_data/knowledge_point_taxonomy.md` |
| dev_scenarios.json | JSON | Development set with 100 scenarios for self-testing | `attachments/input_data/dev_scenarios.json` |
| output_schema.json | JSON | Submission result format example | `attachments/input_data/output_schema.json` |
| requirements.txt | Text | Required Python dependency list | `attachments/requirements.txt`, `attachments/input_data/requirements.txt` |
| environment_setup.md | Markdown | Environment setup and verification steps | `attachments/environment_setup.md`, `attachments/input_data/environment_setup.md` |

## Deliverable Requirements

- train.py | Python source file
- infer.py | Python source file
- models/ | optional directory for trained models / indexes required by infer.py
- submission.json | JSON
- requirements.txt | text
- README.md | Markdown
