> instructions
#### Dependencies (Libraries)
- Computer Vision Toolbox

#### Usage 
- Open build1.m in MATLAB.
- [Optional] Set output path for a generated .csv file at the end.
- Load Video from a directory.
- Follow the pop-up messages, select regions (boxes) for motion and number reading (in order).
  * it is recommended that for reading a number, select the region such that it is as restricted to the number as possible for better reading (only include where the digits are displayed).
- [Optional] Override rep if necessary by clicking RESET button.
- Upon detecting motion, the box will turn red (no motion), green (in motion), blue (video finished).


#### Output
- '{video_name}.csv' containing ITERATIONS / START_TIME / END_TIME / DURATION / MIN_NUMBER / MAX_NUMBER / AVG_NUMBER.

#### Constraints/Limitations
- The number is accepted only if in range [50, 200].
- The video skips 3 frames at each time of reading for expedited runthrough.
- The conditions/thresholds for motion detection may vary for other types of videos than the sample.

> Sample videos
Link: https://drive.google.com/drive/u/0/folders/1xV9lRZPhbg1SBrieYeb4i5T1OZwsIZnF