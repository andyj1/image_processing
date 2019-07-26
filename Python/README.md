> instructions
#### Dependencies (Libraries)
- Tesseract OCR: https://github.com/tesseract-ocr/tesseract/wiki (need to install this to run)
- Pytesseract (OCR) in Python
- Tkinter (GUI tool)
- Matplotlib (Image Figures)
- Pillow (Image, ImageTk for Image Procecssing)
- Scikit-Image (Structural Similarity Index)
- OpenCV (Image Processing)
- Numpy/time/csv

#### Usage (executable file)
Windows/Linux/Mac:
- Select options: Turn off ongoing displays, select user-defined region for heart rate.
- Select Video.
- Follow the popup message to select regions.
- Upon completion, the region turns blue and a csv-formatted file is created.

#### Key
- Keyboard: 'q' to exit window
- Selecting  region: 'left click press' to start cropping (upper left corner point), 'left click release' to finish cropping (lower right corner point).

#### Output
- '{video_name}.csv' containing ITERATIONS / START_TIME / END_TIME / DURATION / MIN_HR / MAX_HR / AVG_HR.
- The output will be located where executable (Python version) is located, or where the loaded video is located (MATLAB version).

#### Constraints/Limitations
- Tesseract needs to be installed to proceed (see below for installation).
- If running on Windows, it may take a few seconds to open, depending on the machine.
- The heart rate region, if user-defined, may not read the numbers correctly due to precision required for OCR.
- The 'default' hart rate reading mode assumes that the heart rate reading device is positioned at the pre-defined location (as in sample videos).
- If running the python file in terminal, may need graphical interface support (i.e. launch Xming).
  - run 'export DISPLAY=:0.0' to set the path variable for GUI windows.

#### If modules are all installed, build from python file with pyinstaller
- pyinstaller {file_name}.py --name {output_name} --onefile -F --windowed --icon=appicon.ico --hidden-import=tkinter --hidden-import=tkinter.filedialog --hidden-import=tkinter.font --hidden-import=warnings --hidden-import=pywt._extensions._cwt --hidden-import=matplotlib --hidden-import=PIL.Image --hidden-import=PIL._tkinter_finder --hidden-import=numpy --hidden-import=skimage.measure --hidden-import=cv2 --hidden-import=pytesseract --hidden-import=datetime --hidden-import=os --hidden-import=tkinter.messagebox --hidden-import=csv

---
##### Install Tesseract 4.0
>>Tesseract is an open source text recognizer (OCR) Engine, available under the Apache 2.0 license. It can be used directly, or (for programmers) using an API to extract printed text from images. It supports a wide variety of languages

- General Guide: https://github.com/tesseract-ocr/tesseract/wiki

###### (1) installing Tesseract
- Windows: install latest installer from https://github.com/UB-Mannheim/tesseract/wiki
- Linux: 
  ```shell
    sudo apt install tesseract-ocr
    sudo apt install libtesseract-dev
  ```
- MacOS:
    ```shell
    # if Homebrew not installed, install Homebrew
    mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
    # if tesseract 3 is already installed, unlink
    # brew unlink tesseract
    brew  install tesseract --HEAD
    # check version
    tesseract --version
    # to use tesseract as command line tool
    tesseract {image.jpg} {output} -l eng -- oem 0 --psm 3
    # * psm: page segmentation mode: default at 3
    # * oem mode:
    #  0    Legacy engine only.
    #  1    Neural nets LSTM engine only.
    #  2    Legacy + LSTM engines.
    #  3    Default, based on what is available.
    # https://www.learnopencv.com/deep-learning-based-text-recognition-ocr-using-tesseract-and-opencv/ (make sure .traineddata file is in the right path)
    ```

###### (2) installing trained data files
- copy the attached files eng.traineddata, eng.user-patterns eng.user-words to the path below
  ```script
    cp {eng.traineddata, eng.user-patterns, eng.user-words} PATH  (replace 'PATH' with system path to Tesseract)
  ```
- System path (Install training files from https://github.com/tesseract-ocr/tessdata (only works with 4.0 version) to...)
  - Windows: 
  ```console C:\Program Files\Tesseract-OCR\tessdata ``` or ```console C:\Program Files (x86)\Tesseract-OCR\tessdata ```
  - Linux:
  ```console /usr/share/tesseract-ocr/tessdata ``` or ```console /usr/share/tessdata ``` or ```console /usr/share/tesseract-ocr/4.00/tessdata ```
  - MacOS:
  ```console /usr/local/Cellar/tesseract/4.0.0/share/tessdata/ ```
- Listing all paths to Tesseract:
  ```script
  which tesseract # Linux, WSL
  brew list tesseract # MacOS
  ```
