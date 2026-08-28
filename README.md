# 🍃 MoruScan: A Mobile Application for Image-Based Detection of Leaf Spot Disease

> **NaSRIC 2026 Qualifier Paper**
> This project served as a qualifying study for the **National Student Research and Innovation Conference (NaSRIC) 2026**.

---

## 📖 Table of Contents

1. [Description](#-description)
2. [Research Objectives](#-research-objectives)
3. [Research Methodology](#-research-methodology)
4. [Results](#-results)
5. [Key Functionality](#-key-functionality)
6. [How to Use the App](#-how-to-use-the-app)
7. [Requirements](#-requirements)
8. [How to Download the Source Code](#-how-to-download-the-source-code)
9. [Configuration & Dependencies](#-configuration--dependencies)
10. [Project Structure](#-project-structure)
11. [Dataset](#-dataset)
12. [Acknowledgments](#-acknowledgments)
13. [Contact](#-contact)
14. [License](#-license)

---

## 📱 Description

**MoruScan** is a mobile application designed to detect **leaf spot disease** in mulberry (*Morus* spp.) leaves using an on-device machine learning model. Built with **Flutter** and powered by a **YOLOv8s**-based detection model converted to TensorFlow Lite, MoruScan enables farmers, sericulture practitioners, and agricultural extension workers to quickly assess the health status of mulberry leaves directly from their smartphones — no internet connection required for inference.

The app analyzes captured or gallery-selected leaf images, detects leaf spot regions, computes an **infection severity index**, and classifies the leaf as **Healthy**, **Low**, **Moderate**, or **High** severity. It then provides actionable recommendations (in both English and Filipino/Tagalog) to help users respond appropriately, supporting better mulberry cultivation and sericulture practices.

---

## 🎯 Research Objectives

The main objective of this study was to develop a mobile application with a machine learning model capable of detecting the health status of mulberry leaves to support mulberry cultivation and sericulture practices. Specifically, the study sought to achieve the following objectives:

1. To **collect and preprocess** a dataset of mulberry leaf images representing both healthy leaves and leaf spot–infected leaves.
2. To **train the model** in detecting leaf spot disease and its severity level.
3. To **evaluate the performance** of the model and the correctness of severity prediction.
4. To **develop the mobile application** integrating the trained model for disease detection.

---

## 🔬 Research Methodology

### Research Design

This study employed both **descriptive** and **developmental** research methodologies.

- **Descriptive research** was applied to evaluate model performance using quantitative metrics — **mAP50, precision, recall, and F1-score**.
- **Developmental research** was applied in the design, training, and integration of the machine learning model into a fully functioning mobile application (MoruScan).

---

## 📊 Results

Different model configurations were evaluated on a common test set. The performance evaluation of the **YOLOv8s** model revealed that the highest accuracy was obtained using a **learning rate of 0.002** trained over **150 epochs**, achieving the following results:

| Metric | Score |
|---|---|
| **mAP50** | **90.35%** |
| **Precision** | 88.58% |
| **Recall** | 87.31% |
| **F1-Score** | 87.94% |

This configuration demonstrated a strong balance between precision and recall, reflecting both accurate detection and reliable sensitivity to diseased regions. The resulting F1-score further confirms the model's consistency in identifying mulberry leaf spots while minimizing false detections. These results suggest that the integration of **patching** enhanced the model's ability to learn localized disease features and effectively handle complex leaf backgrounds, leading to optimal overall performance.

---

## ⚙️ Key Functionality

- 📷 **Image Capture & Selection** — Capture leaf photos directly with the device camera or select existing images from the gallery.
- 🔍 **On-Device Disease Detection** — Uses a TensorFlow Lite–converted YOLOv8s model to detect leaf spot regions without requiring an internet connection.
- 🌿 **Leaf Verification (Encoder + Gallery Matching)** — An embedding-based encoder model cross-checks the captured image against a mulberry leaf "fingerprint" gallery to confirm the image is actually a mulberry leaf before running full detection.
- 📈 **Severity Index Calculation** — Computes an infection percentage based on infected vs. total leaf pixels, then classifies severity as:
  - **Healthy** (0%)
  - **Low Severity** (0.01–2%)
  - **Moderate Severity** (2–7%)
  - **High Severity** (>7%)
- 📝 **Bilingual Recommendations** — Provides tailored care recommendations in both **English** and **Tagalog** based on the detected severity level.
- 🕓 **Scan History** — Automatically logs every scan (image, severity, infection index, detections, and timestamp) for later reference, with support for filtering.
- 💾 **Persistent Last-Scan State** — Restores the most recent scan result automatically when reopening the app.
- 📊 **Usage Statistics** — Tracks total scans performed and total spots detected over time.
- 🗑️ **History Management** — Allows users to clear scan history from the Settings page.
- 📘 **In-App Guide** — A dedicated Info page walks users through how to use the app, photography tips for accurate detection, and how to interpret results — presented bilingually.

---

## 📲 How to Use the App

1. **Open the App** — Launch MoruScan on your mobile device. You'll land on the Home tab.
2. **Capture or Select a Leaf Image** — Tap the **Camera** button to take a photo of a mulberry leaf, or the **Gallery** button to choose an existing photo.
3. **Automatic Analysis** — The app verifies the image is a mulberry leaf, then detects leaf spots and calculates the severity index. The result banner will show **Healthy**, **Low**, **Moderate**, or **High** severity.
4. **View the Detailed Report** — Tap the result card to open a full breakdown, including infection percentage, leaf/infected pixel counts, and severity-specific recommendations.
5. **Check Scan History** — Go to the **History** tab to review all previous scans, complete with images, severity levels, and recommendations.
6. **Read the Guide** — Visit the **Info** tab anytime for step-by-step usage instructions, photography tips, and an explanation of each severity level.
7. **Manage Settings** — Use the **Settings** tab to clear scan history or view app/about information.

> 💡 **Tip for best results:** Use good, natural lighting; keep the camera steady and focused; capture the full leaf or the most affected area; and avoid obstructions such as fingers or overlapping leaves.

---

## 🧰 Requirements

### To Run the App (End Users)
- Android device running **Android 6.0 (API 23)** or higher
- Camera and storage/gallery permissions enabled
- ~100–150 MB of free storage (for the app and its bundled ML models)
- *No internet connection required* for scanning — inference runs entirely on-device

### To Build/Develop the App (Developers)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) — compatible with Dart SDK `^3.9.2`
- Android Studio or VS Code with the Flutter/Dart plugins
- Android SDK & an emulator or physical Android device for testing
- Git (for cloning the repository)

---

## ⬇️ How to Download the Source Code

1. **Clone the repository** using Git:
   ```bash
   git clone https://github.com/<your-username>/moruscan_app.git
   cd moruscan_app
   ```
   Alternatively, download the repository as a ZIP file from GitHub (**Code → Download ZIP**) and extract it.

2. **Open the project** in Android Studio or VS Code.

3. Proceed to the [Configuration & Dependencies](#-configuration--dependencies) section below to set up the project before running it.

---

## 🔧 Configuration & Dependencies

### 1. Install Flutter Dependencies

From the project root, run:

```bash
flutter pub get
```

This installs all packages declared in `pubspec.yaml`, including:

| Package | Purpose |
|---|---|
| `tflite_flutter` | Runs the on-device TensorFlow Lite detection & encoder models |
| `image` | Image decoding/processing (preprocessing before inference) |
| `image_picker` | Capturing photos via camera or selecting from gallery |
| `camera` | Direct camera access/control |
| `provider` | State management (see `scan_state_service.dart`) |
| `shared_preferences` | Persisting scan history, stats, and last-scan state locally |
| `path_provider` / `path` | File system path handling for stored images |
| `google_fonts` | Custom typography (Poppins, etc.) |
| `fl_chart` | Charting/visualizing severity or history data |
| `lottie` | Loading/animation assets |
| `shimmer` | Skeleton/shimmer loading placeholders |
| `flutter_launcher_icons` | Generating custom app launcher icons |
| `cupertino_icons` | iOS-style iconography |

### 2. Add the Required ML Model & Data Assets

MoruScan expects the following asset files to be present under an `assets/` folder at the project root (declared under `flutter: assets:` in `pubspec.yaml`):

```
assets/
├── best_float16.tflite         # Main YOLOv8s leaf-spot detection model (TFLite)
├── labels.txt                  # Class labels for the detection model
├── mulberry_encoder.tflite     # Embedding encoder model for leaf verification
├── fingerprints.json           # Metadata for mulberry "fingerprint" gallery
├── mulberry_fingerprint.npy    # Reference embedding vectors
└── mulberry_gallery.bin        # Compiled mulberry leaf gallery data
```

> ⚠️ **Important:** These model and asset files are **not included** in the base repository due to file size. Place them in the `assets/` directory exactly as listed above before building — otherwise the app will fail to load the models at runtime.

### 3. Configure the App Icon (Optional)

The app icon is configured via `flutter_launcher_icons` in `pubspec.yaml`, pointing to `assets/icon/icon2.png`. Place your icon image at that path, then generate launcher icons with:

```bash
flutter pub run flutter_launcher_icons
```

### 4. Run the App

Connect an Android device or start an emulator, then run:

```bash
flutter run
```

To build a release APK:

```bash
flutter build apk --release
```

The generated APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🗂️ Project Structure

```
moruscan_app/
├── lib/
│   ├── main.dart                # App entry point
│   ├── moruscan_main.dart       # Bottom-navigation shell (Home, History, Info, Settings)
│   ├── moruscan_home.dart       # Home/scan screen — capture, detect, verify, severity analysis
│   ├── history_page.dart        # Scan history list, storage, and record management
│   ├── info_page.dart           # In-app guide: how-to, tips, and severity explanations
│   ├── settings_page.dart       # Settings, history clearing, about section
│   ├── recognition.dart         # Recognition model (bounding box, label, score)
│   └── scan_state_service.dart  # Shared scan state (Provider/ChangeNotifier)
├── assets/                      # ML models, labels, and reference data (see above)
├── pubspec.yaml                 # Project metadata and dependencies
└── README.md
```

---

## 🌱 Dataset

The mulberry leaf image dataset used to train and evaluate the detection model was **carefully collected, curated, and validated by an expert from the Don Mariano Marcos Memorial State University – Sericulture Research and Development Institute (DMMMSU-SRDI)**, ensuring the accuracy and reliability of both the healthy and leaf spot–infected leaf annotations used in this study.

The dataset itself is **not publicly bundled** with this repository. Researchers or practitioners interested in obtaining a copy of the dataset for academic or research purposes may request access directly from the author (see [Contact](#-contact) below).

---

## 🙏 Acknowledgments

- **DMMMSU-SRDI (Don Mariano Marcos Memorial State University – Sericulture Research and Development Institute)** for their expert validation of the mulberry leaf dataset used in this study.
- This study/paper is a qualifier at the **NaSRIC 2026 (National Student Research and Innovation Conference 2026)**.

---

## 📬 Contact

For inquiries, collaboration requests, or to request a copy of the dataset, please reach out via email:

📧 **molina.reymarherlan@gmail.com**

---

## 📄 License

This project was developed as part of an undergraduate thesis for academic purposes. Please contact the author regarding reuse, citation, or collaboration.
