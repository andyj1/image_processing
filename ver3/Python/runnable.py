#!/usr/bin/env python

import csv
import datetime
import os
import time
import warnings

# GUI
import tkinter as tk
from tkinter import filedialog, font, messagebox

# Graph, arrays
import matplotlib
from matplotlib import pyplot as plt
import numpy as np
# Tesseract OCR (digit recognition)
import pytesseract
# OpenCV, Pillow Image Processing
import cv2
from PIL import Image, ImageTk
# Structural Similarity Index (SSIM)
from skimage.measure import compare_ssim as ssim

# Backend for matplotlib, ignoring verbose warnings
matplotlib.use('Agg')
warnings.filterwarnings("ignore")

# -----------------------------------------------------------------------------
# Video class
# -----------------------------------------------------------------------------
class VideoCapture:
    global root 
    
    def __init__(self, vsrc):
        self.video = cv2.VideoCapture(vsrc)
        if not self.video.isOpened():
            errmsg = tk.Toplevel(root)
            display = tk.Label(errmsg, text="Error loading the video!")
            display.pack()   
            raise ValueError("Unable to open video:", vsrc)
        # get video properties
        self.width = self.video.get(cv2.CAP_PROP_FRAME_WIDTH)
        self.height = self.video.get(cv2.CAP_PROP_FRAME_HEIGHT)
        
    def get_fps(self):
        fps = int(self.video.get(cv2.CAP_PROP_FPS))
        return fps

    def offset_frame_pos(self, frame):
        curr_frame = self.video.get(cv2.CAP_PROP_POS_FRAMES)
        self.video.set(cv2.CAP_PROP_POS_FRAMES, curr_frame+frame)
        
    def get_frame(self):
        if self.video.isOpened():
            ret, frame = self.video.read()
            if ret:
                # return cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                return frame # BGR format
            else:
                return None
        else:
            return None
        
    def get_time(self):
        return self.video.get(cv2.CAP_PROP_POS_MSEC)
    
    def get_position(self):
        return self.video.get(cv2.CAP_PROP_POS_FRAMES)
    
    def get_length(self):
        return self.video.get(cv2.CAP_PROP_FRAME_COUNT)
    
    # release the video automatically when the object is destroyed
    def __del__(self):
        if self.video.isOpened():
            self.video.release()
# end VideoCapture        

# -----------------------------------------------------------------------------
# Main window class
# -----------------------------------------------------------------------------
class Main:
    def __init__(self, root_window, video_source):
        global root, v, default_hr
        
        print("Loaded:",video_source)
        self.window = root_window
        self.window.title(video_source)
        self.video_source = video_source
        
        # initialize global variables
        self.hr_pt1 = (0,0)
        self.hr_pt2 = (-1,-1)
        self.roi_pt1 = (0,0)
        self.roi_pt2 = (-1,-1)
        self.frame_count = 0
        self.start_x = 0
        self.start_y = 0    
        self.cropped_hr = False
        self.cropped_roi = False
        
        
        self.store_ssim = [1]
        self.starting = False
        
        self.peg_start2 = 0
        self.peg_end2 = 0
        
        self.start_ssim = -1
        self.whitepixels = [0]
        self.deltas = []
        
        self.delta_curr = 0
        self.delta_prev1 = 0
        self.delta_prev2 = 0
        self.delta_prev3 = 0
        self.ssim_curr = 0
        self.ssim_prev1 = 0
        self.ssim_prev2 = 0
        self.ssim_prev3 = 0
        
        self.output = []
        self.heart_rate_text = ""
        self.max_hr = 0
        self.min_hr = 0
        self.heart_rates = []
        self.filtered_hrs = []
        self.new_frame = None
        
        # get video
        self.video = VideoCapture(self.video_source)
        self.video_width = self.video.width
        self.video_height = self.video.height

        self.fps = self.video.get_fps()
        print("FPS:", self.fps)
        
        self.current = None
        self.original = None
        self.current = None
        self.timed = 0
        self.cropped_display = None
        self.new_width = 0
        self.new_height = 0
        self.orig_crop = None
        self.offset = self.fps//2
        self.first_start = False
        self.count = 1
        
        self.start_conditions = False
        self.end_conditions = False
        self.initiate = False

        # Gets both half the screen width/height and window width/height
        # Positions the window in the center of the page.
        positionRight = int(root.winfo_screenwidth()/2 - root.winfo_reqwidth()/2)
        positionDown = int(root.winfo_screenheight()/2 - root.winfo_reqheight()/2)
        
        root.geometry("+{}+{}".format(positionRight-800, positionDown-400))
        # create canvas for current window
        self.video_window = tk.Toplevel(root)
        self.video_window.configure(width=980, height=540)
        self.video_window.geometry("+{}+{}".format(positionRight-800, positionDown-250))
        self.canvas = tk.Canvas(self.video_window, width = int(self.video_width//2), height = int(self.video_height//2))
        self.canvas.pack()
        
        self.myFont = font.Font(family="Times New Roman bold", size=10)
        # -----------------------------------------------------------------------------
        # heart rate window
        # create canvas for heart rate window
        # -----------------------------------------------------------------------------
        self.hr_window = tk.Toplevel(self.video_window)
        self.hr_window.configure(width=700, height=1500)
        self.hr_window.geometry("+{}+{}".format(positionRight+450, positionDown-250))
        self.hr_window.title("Heart Rate Display")
        self.hr_text = tk.Text(self.hr_window, wrap=tk.WORD, height=1, width=30)
        self.hr_text.configure(font=self.myFont, background="white")
        self.hr_text.insert(tk.INSERT, "HEART RATE")
        self.hr_text.pack()     
        self.hr_text1 = tk.Text(self.hr_window, wrap=tk.WORD, height=1, width=30)
        self.hr_text1.configure(font=self.myFont, background="white")
        self.hr_text1.insert(tk.INSERT, "START: ")
        self.hr_text1.pack()
        self.hr_time1 = tk.Text(self.hr_window, wrap=tk.WORD, height=1, width=30)
        self.hr_time1.configure(font=self.myFont, background="white")
        self.hr_time1.insert(tk.INSERT, "time: ")
        self.hr_time1.pack()
        self.hr_canvas1 = tk.Canvas(self.hr_window, width = 200, height = 100)
        self.hr_canvas1.pack()
        self.hr_text2 = tk.Text(self.hr_window, wrap=tk.WORD, height=1, width=30)
        self.hr_text2.configure(font=self.myFont, background="white")
        self.hr_text2.insert(tk.INSERT, "END: ")
        self.hr_text2.pack()
        self.hr_time2 = tk.Text(self.hr_window, wrap=tk.WORD, height=1, width=30)
        self.hr_time2.configure(font=self.myFont, background="white")
        self.hr_time2.insert(tk.INSERT, "time: ")
        self.hr_time2.pack()
        self.hr_canvas2 = tk.Canvas(self.hr_window, width = 200, height = 100)
        self.hr_canvas2.pack()
        self.hr_final_text = tk.Text(self.hr_window, wrap=tk.WORD, height=11, width=30)
        self.hr_final_text.configure(font=self.myFont, background="white")
        self.hr_final_text.insert(tk.INSERT, "All Detected Heart Rates [bpm] \n")
        self.hr_final_text.pack()
        
        # -----------------------------------------------------------------------------
        # current image window at start & end
        # -----------------------------------------------------------------------------
        self.curr_window = tk.Toplevel(self.video_window)
        self.curr_window.configure(width=700, height=1500)
        self.curr_window.geometry("+{}+{}".format(positionRight+230, positionDown-250))
        self.curr_window.title("Motion Detection Display")
        self.curr_text = tk.Text(self.curr_window, wrap=tk.WORD, height=1, width=30)
        self.curr_text.configure(font=self.myFont, background="white")
        self.curr_text.insert(tk.INSERT, "TIME")
        self.curr_text.pack()     
        self.curr_text1 = tk.Text(self.curr_window, wrap=tk.WORD, height=1, width=30)
        self.curr_text1.configure(font=self.myFont, background="white")
        self.curr_text1.insert(tk.INSERT, "START")
        self.curr_text1.pack()
        self.curr_time1 = tk.Text(self.curr_window, wrap=tk.WORD, height=1, width=30)
        self.curr_time1.configure(font=self.myFont, background="white")
        self.curr_time1.insert(tk.INSERT, "time: ")
        self.curr_time1.pack()
        self.curr_canvas1 = tk.Canvas(self.curr_window, width = 200, height = 100)
        self.curr_canvas1.pack()
        self.curr_text2 = tk.Text(self.curr_window, wrap=tk.WORD, height=1, width=30)
        self.curr_text2.configure(font=self.myFont, background="white")
        self.curr_text2.insert(tk.INSERT, "END")
        self.curr_text2.pack()
        self.curr_time2 = tk.Text(self.curr_window, wrap=tk.WORD, height=1, width=30)
        self.curr_time2.configure(font=self.myFont, background="white")
        self.curr_time2.insert(tk.INSERT, "time: ")
        self.curr_time2.pack()
        self.curr_canvas2 = tk.Canvas(self.curr_window, width = 200, height = 100)
        self.curr_canvas2.pack()
        self.time_final_text = tk.Text(self.curr_window, wrap=tk.WORD, height=11, width=30)
        self.time_final_text.configure(font=self.myFont, background="white")
        self.time_final_text.insert(tk.INSERT, "Durations [sec] \n")
        self.time_final_text.pack()
        
        # instructions
        self.inst_window = tk.Toplevel(self.video_window)
        self.inst_window.configure(width=100, height=300)
        if v.get() == 0:
            self.inst_window.geometry("+{}+{}".format(positionRight+230, positionDown+300))
        else:
            self.inst_window.geometry("+{}+{}".format(positionRight+230, positionDown-250))
        self.inst_window.title("----Instructions----")
        self.inst_text = tk.Text(self.inst_window, wrap=tk.WORD, height=10, width=80)
        self.inst_text.configure(font=self.myFont)
        self.inst_text.insert(tk.INSERT, "1. Select a video \n \t * Display: OFF to turn off ongoing view \n \t * HR: User-Defined to manually select region for Heart Rate \n 2. Select Motion Detection region (upper left to bottom right) \n 3. Select Heart Rate region (upper left to bottom right) \n 4. <Colors> \n \t Red: No Motion Detected \n \t Green: Motion Detected \n \t Blue: Video Finished")
        self.inst_text.pack()

        # set key and mouse callbacks
        self.video_window.bind("q", lambda x: self.video_window.destroy())
        self.video_window.bind("r", self.reset)
        self.video_window.bind("<ButtonPress-1>", self.on_press_ROI)
        self.video_window.bind("<ButtonRelease-1>", self.on_release_ROI)

        # destroy windows
        if v.get() == 1:
            self.hr_window.destroy()
            self.curr_window.destroy()
        self.update()
        self.window.mainloop()

    def reset(self):
        self.cropped_hr = False
        self.cropped_roi = False
        self.video_window.bind("q", lambda x: self.window.destroy())
        self.video_window.bind("<ButtonPress-1>", self.on_press_ROI)
        self.video_window.bind("<ButtonRelease-1>", self.on_release_ROI)
    
    def on_press_heart_rate(self, event):
        self.start_x, self.start_y = event.x, event.y
    
    def on_release_heart_rate(self, event):
        self.hr_pt1 = (int(self.start_x), int(self.start_y))
        self.hr_pt2 = (int(event.x), int(event.y))
        print("clicked coordinates (HR):", [self.hr_pt1, self.hr_pt2])
        self.cropped_hr = True
        
        # set original to next frame to compare
        self.original = resize_frame(self.video.get_frame())
        self.original = self.magnify(self.original,1000)
        self.original = cv2.fastNlMeansDenoising(self.original)
        (x1,y1),(x2,y2) = self.roi_pt1, self.roi_pt2
        self.orig_crop = self.original[y1:y2, x1:x2]
        self.orig_crop = cv2.cvtColor(self.orig_crop, cv2.COLOR_BGR2GRAY)

        self.video_window.unbind("<ButtonPress-1>")
        self.video_window.unbind("<ButtonRelease-1>")
        self.window.after(15, self.update)
    
    def on_press_ROI(self, event):
        self.start_x, self.start_y = event.x, event.y
    
    def on_release_ROI(self, event):
        self.roi_pt1 = (int(self.start_x), int(self.start_y))
        self.roi_pt2 = (int(event.x), int(event.y))
        print("clicked coordinates (ROI):", [self.roi_pt1, self.roi_pt2])
        if default_hr.get() == 1:
            self.video_window.unbind("<ButtonPress-1>")
            self.video_window.unbind("<ButtonRelease-1>")
            self.video_window.bind("<ButtonPress-1>", self.on_press_heart_rate)
            self.video_window.bind("<ButtonRelease-1>", self.on_release_heart_rate)
        else:
            # set original to next frame to compare
            self.original = resize_frame(self.video.get_frame())
            self.original = self.magnify(self.original,1000)
            self.original = cv2.fastNlMeansDenoising(self.original)
            self.orig_crop = self.original[int(self.start_y):int(event.y), int(self.start_x):int(event.x)]
            self.orig_crop = cv2.cvtColor(self.orig_crop, cv2.COLOR_BGR2GRAY)
            self.video_window.unbind("<ButtonPress-1>")
            self.video_window.unbind("<ButtonRelease-1>")
        self.cropped_roi = True
        self.window.after(15, self.update)
    # -----------------------------------------------------------------------------
    # recursively called update function
    # -----------------------------------------------------------------------------
    def update(self):
        if v.get() == 0:
            self.curr_text.delete(1.0, tk.END)
            self.curr_text.insert(tk.INSERT, str(int(self.video.get_time()/1000//60))+' min '+str(round(self.video.get_time()/1000%60,2))+' sec')

        # denoise frame upon loading
        # _ = self.video.get_frame()
        new_frame = self.video.get_frame()
        if new_frame is not None:
            self.new_frame = new_frame # for later
            self.current = new_frame

            # resize for screen 
            self.current = resize_frame(self.current)
            self.current = self.magnify(self.current, 1000)
            self.current = cv2.fastNlMeansDenoising(self.current)
            h, w = self.current.shape[0:2]
            heart_rate = None
            # default hr
            if default_hr.get() == 0: 
                h1, w1 = self.new_frame.shape[0:2]
                heart_rate = new_frame[:, w1//2:]
                heart_rate = heart_rate[70:120, 70:140]
            # user-defined hr
            else:          
                heart_rate = self.current[self.hr_pt1[1]:self.hr_pt2[1], self.hr_pt1[0]:self.hr_pt2[0]]
        
            # initial
            if self.initiate == False:
                # if display ON, heart rate not default, wait for heart rate
                if default_hr.get()==1:
                    # initially when not cropped, constantly update image
                    if self.cropped_hr == False and self.cropped_roi == False:
                        # blur
                        self.blur = cv2.blur(self.current, ksize=(11,11))
                        self.display = Image.fromarray(cv2.cvtColor(self.blur, cv2.COLOR_BGR2RGB))
                        self.display = ImageTk.PhotoImage(self.display)
                        self.canvas.configure(width=w, height=h)
                        self.canvas.create_image(0, 0, image=self.display, anchor=tk.NW)
                        self.canvas.image = self.display

                        messagebox.showinfo("Information","Select Motion Detection Region")
                        self.display = Image.fromarray(cv2.cvtColor(self.current, cv2.COLOR_BGR2RGB))
                        self.display = ImageTk.PhotoImage(self.display)
                        self.canvas.configure(width=w, height=h)
                        self.canvas.create_image(0, 0, image=self.display, anchor=tk.NW)
                        self.canvas.image = self.display
                    elif self.cropped_hr == False and self.cropped_roi == True:
                        # blur
                        self.blur = cv2.blur(self.current, ksize=(11,11))
                        self.display = Image.fromarray(cv2.cvtColor(self.blur, cv2.COLOR_BGR2RGB))
                        self.display = ImageTk.PhotoImage(self.display)
                        self.canvas.configure(width=w, height=h)
                        self.canvas.create_image(0, 0, image=self.display, anchor=tk.NW)
                        self.canvas.image = self.display

                        messagebox.showinfo("Information","Select Heart Rate Region")
                        # highlight box in red
                        cv2.rectangle(self.current, self.roi_pt1, self.roi_pt2, color=(0,0,255), thickness=2)
                        self.cropped_display = cv2.cvtColor(self.current, cv2.COLOR_BGR2RGB)
                        self.cropped_display = Image.fromarray(self.cropped_display)
                        self.cropped_display = ImageTk.PhotoImage(self.cropped_display)
                        self.canvas.configure(width=w, height=h)
                        self.canvas.create_image(0, 0, image=self.cropped_display, anchor=tk.NW)
                        self.canvas.image= self.cropped_display
                    elif self.cropped_hr == True and self.cropped_roi == True:    
                        cv2.rectangle(self.current, self.hr_pt1, self.hr_pt2, color=(0,0,255), thickness=2)
                        cv2.rectangle(self.current, self.roi_pt1, self.roi_pt2, color=(0,0,255), thickness=2)
                        # draw the current window
                        self.cropped_display = cv2.cvtColor(self.current, cv2.COLOR_BGR2RGB)
                        self.cropped_display = Image.fromarray(self.cropped_display)
                        self.cropped_display = ImageTk.PhotoImage(self.cropped_display)
                        self.canvas.configure(width=w, height=h)
                        self.canvas.create_image(0, 0, image=self.cropped_display, anchor=tk.NW)
                        self.canvas.image= self.cropped_display
                        self.initiate = True
                        self.window.after(15, self.update)
                # if display ON, heart rate default, skip checking for heart rate cropped
                elif default_hr.get()==0:
                    # initially when not cropped, constantly update image
                    if self.cropped_roi == False:
                        self.blur = cv2.blur(self.current, ksize=(11,11))
                        self.display = Image.fromarray(cv2.cvtColor(self.blur, cv2.COLOR_BGR2RGB))
                        self.display = ImageTk.PhotoImage(self.display)
                        self.canvas.configure(width=w, height=h)
                        self.canvas.create_image(0, 0, image=self.display, anchor=tk.NW)
                        self.canvas.image = self.display

                        messagebox.showinfo("Information","Select Motion Detection Region")
                        self.display = Image.fromarray(cv2.cvtColor(self.current, cv2.COLOR_BGR2RGB))
                        self.display = ImageTk.PhotoImage(self.display)
                        self.canvas.configure(width=w, height=h)
                        self.canvas.create_image(0, 0, image=self.display, anchor=tk.NW)
                        self.canvas.image = self.display
                    else:
                        # highlight box in red
                        cv2.rectangle(self.current, self.roi_pt1, self.roi_pt2, color=(0,0,255), thickness=2)
                        self.cropped_display = cv2.cvtColor(self.current, cv2.COLOR_BGR2RGB)
                        self.cropped_display = Image.fromarray(self.cropped_display)
                        self.cropped_display = ImageTk.PhotoImage(self.cropped_display)
                        self.canvas.configure(width=w, height=h)
                        self.canvas.create_image(0, 0, image=self.cropped_display, anchor=tk.NW)
                        self.canvas.image= self.cropped_display
                        self.initiate = True
                        self.window.after(15, self.update)
                    
                # if display ON, heart rate default, skip checking for heart rate

            # self.initiate is True
            else:
                # draw the current window
                cv2.rectangle(self.current, self.hr_pt1, self.hr_pt2, color=(0,0,255), thickness=2)
                cv2.rectangle(self.current, self.roi_pt1, self.roi_pt2, color=(0,0,255), thickness=2)
                self.cropped_display = cv2.cvtColor(self.current, cv2.COLOR_BGR2RGB)
                self.cropped_display = Image.fromarray(self.cropped_display)
                self.cropped_display = ImageTk.PhotoImage(self.cropped_display)
                self.canvas.configure(width=w, height=h)
                self.canvas.create_image(0, 0, image=self.cropped_display, anchor=tk.NW)
                self.canvas.image= self.cropped_display

                # orig_crop = self.orig_crop #temp_original
                [(x1,y1),(x2,y2)] = [self.roi_pt1, self.roi_pt2]
                curr_crop = self.current[y1:y2, x1:x2]
                curr_crop_gray = cv2.cvtColor(curr_crop, cv2.COLOR_BGR2GRAY)
                # self.orig_crop is already in grayscale
                # compare grayscale images -- original and current, both cropped to ROI
                results = self.compare_images(self.orig_crop, curr_crop_gray)
                
                _, orig_thresh = cv2.threshold(self.orig_crop, 127, 255, cv2.THRESH_BINARY)
                _, curr_thresh = cv2.threshold(curr_crop_gray, 127, 255, cv2.THRESH_BINARY)
                diff = np.subtract(orig_thresh, curr_thresh)
                diff_rgb = cv2.cvtColor(diff, cv2.COLOR_GRAY2RGB)
                
                gray_diff = np.subtract(self.orig_crop, curr_crop_gray)
                _, gray_diff_count = cv2.threshold(diff,200, 255, cv2.THRESH_BINARY)
                
                self.store_ssim.append(round(results['ssim'], 3))
                self.whitepixels.append(cv2.countNonZero(gray_diff_count))

                if self.whitepixels[0] == 0:
                    self.whitepixels[0] = cv2.countNonZero(gray_diff_count)
                
                self.delta_curr = self.whitepixels[self.frame_count]
                try:
                    self.delta_prev1 = self.whitepixels[self.frame_count-1]
                    self.delta_prev2 = self.whitepixels[self.frame_count-2]
                    self.delta_prev3 = self.whitepixels[self.frame_count-3]
                except:
                    self.delta_prev1 = 0
                    self.delta_prev2 = 0
                    self.delta_prev3 = 0
                    
                self.ssim_curr = self.store_ssim[self.frame_count]
                try:
                    self.ssim_prev1 = self.store_ssim[self.frame_count-1]
                    self.ssim_prev2 = self.store_ssim[self.frame_count-2]
                    self.ssim_prev3 = self.store_ssim[self.frame_count-3]
                except:
                    self.ssim_prev1 = 0
                    self.ssim_prev2 = 0
                    self.ssim_prev3 = 0
                    
                # ------------------------------------------------
                # update video window if interval is started
                # self.starting condition defined below
                # ------------------------------------------------
                if self.starting==True:
                    # update window when cropped to green
                    alpha = 0.01
                    cv2.rectangle(self.current, self.roi_pt1, self.roi_pt2, color=(0,255,0), thickness=5)
                    cv2.addWeighted(self.current, alpha, self.current, 1 - alpha, 0, self.current)
                    self.cropped_display = cv2.cvtColor(self.current, cv2.COLOR_BGR2RGB)
                    self.cropped_display = Image.fromarray(self.cropped_display)
                    self.cropped_display = ImageTk.PhotoImage(self.cropped_display)
                    self.canvas.configure(width=w, height=h)
                    self.canvas.create_image(0, 0, image=self.cropped_display, anchor=tk.NW)
                    self.canvas.image = self.cropped_display                                 
                    # ------------------------------------------------
                    # heart rate: read for text only if within the process interval                    
                    # ------------------------------------------------
                    heart_rate_gray = cv2.cvtColor(heart_rate, cv2.COLOR_BGR2GRAY)
                    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (3,3), anchor=None)
                    imgTopHat = cv2.morphologyEx(heart_rate_gray, cv2.MORPH_TOPHAT, kernel)
                    imgBlackHat = cv2.morphologyEx(heart_rate_gray, cv2.MORPH_BLACKHAT, kernel)
                    imgGrayscalePlusTopHat = cv2.add(heart_rate_gray, imgTopHat)
                    heart_rate_gray = cv2.subtract(imgGrayscalePlusTopHat, imgBlackHat)
                                    
                    heart_rate_gray = cv2.cvtColor(heart_rate_gray, cv2.COLOR_GRAY2RGB)
                    cv2.imwrite('./heart_rate.jpg', heart_rate_gray)
                    im = Image.open('./heart_rate.jpg', mode='r')
                    config = '-l eng --oem 0 --psm 7'
                    text = pytesseract.image_to_string(im, config=config) 
                    
                    # text recognition
                    if text.isdigit():
                        self.heart_rates.append(int(text))
                        self.heart_rate_text = str(text)
                    else:
                        self.heart_rate_text = "N/A"    
                    
                    # ----------------------------------------------------------------------------------
                    # update display at the start of the interval
                    # ----------------------------------------------------------------------------------
                    if self.first_start == False: 
                        if v.get() == 0:
                            # update heart rate canvas
                            heart_rate = self.magnify(heart_rate, 200)
                            self.cropped_display = cv2.cvtColor(heart_rate, cv2.COLOR_BGR2RGB)
                            self.cropped_display = Image.fromarray(self.cropped_display)
                            self.cropped_display = ImageTk.PhotoImage(self.cropped_display)
                            self.hr_canvas1.configure(width=heart_rate.shape[1], height=heart_rate.shape[0])
                            self.hr_canvas1.create_image(0, 0, image=self.cropped_display, anchor=tk.NW)
                            self.hr_canvas1.image = self.cropped_display
                            
                            # heart rate
                            self.hr_text1.delete(1.0, tk.END)
                            self.hr_text1.insert(tk.INSERT, "START: ")
                            self.hr_text1.insert(tk.END, self.heart_rate_text)
                            
                            # update current image canvas
                            curr_crop = self.magnify(curr_crop, 200)
                            self.cropped_display = cv2.cvtColor(curr_crop, cv2.COLOR_BGR2RGB)
                            self.cropped_display = Image.fromarray(self.cropped_display)
                            self.cropped_display = ImageTk.PhotoImage(self.cropped_display)
                            self.curr_canvas1.configure(width=curr_crop.shape[1], height=curr_crop.shape[0])
                            self.curr_canvas1.create_image(0, 0, image=self.cropped_display, anchor=tk.NW)
                            self.curr_canvas1.image = self.cropped_display
                            
                            # time add
                            self.hr_time1.delete(1.0, tk.END)
                            self.hr_time1.insert(tk.INSERT, "time: ")
                            self.hr_time1.insert(tk.END, str(round(self.peg_start2/1000,ndigits=4))+' sec ('+str(int(self.peg_start2/1000//60))+' min '+str(round(self.peg_start2/1000%60,ndigits=1))+' sec)')    

                            self.curr_time1.delete(1.0, tk.END)
                            self.curr_time1.insert(tk.INSERT, "time: ")
                            self.curr_time1.insert(tk.END, str(round(self.peg_start2/1000,ndigits=4))+' sec ('+str(int(self.peg_start2/1000//60))+' min '+str(round(self.peg_start2/1000%60,ndigits=1))+' sec)')              
                            
                        self.first_start = True

                    # exception to end condiiton
                    if (self.ssim_curr-self.ssim_prev3)>0.6:
                        self.peg_end2 = self.video.get_time()
                        self.timed = (self.peg_end2 - self.peg_start2)/1000
                        # ignore contacts of duration less than 5 seconds
                        if round(self.timed,4) >= 5:
                            print("-----END------")
                            self.starting = False
                            self.first_start = False
                            start_conditions = False
                            end_conditions = False                        
                            if v.get() == 0:
                                heart_rate = self.magnify(heart_rate, 200)
                                self.cropped_display = cv2.cvtColor(heart_rate, cv2.COLOR_BGR2RGB)
                                self.cropped_display = Image.fromarray(self.cropped_display)
                                self.cropped_display = ImageTk.PhotoImage(self.cropped_display)
                                self.hr_canvas2.configure(width=heart_rate.shape[1], height=heart_rate.shape[0])
                                self.hr_canvas2.create_image(0, 0, image=self.cropped_display, anchor=tk.NW)
                                self.hr_canvas2.image = self.cropped_display
                                
                                
                                self.hr_text2.delete(1.0, tk.END)
                                self.hr_text2.insert(tk.INSERT, "END: ")
                                self.hr_text2.insert(tk.END, self.heart_rate_text)
                                    
                                self.hr_time2.delete(1.0, tk.END)
                                self.hr_time2.insert(tk.INSERT, "time: ")
                                self.hr_time2.insert(tk.END, str(round(self.peg_end2/1000,ndigits=4))+' sec ('+str(int(self.peg_end2/1000//60))+' min '+str(round(self.peg_end2/1000%60,ndigits=1))+' sec)')    
                                
                                curr_crop = self.magnify(curr_crop, 200)
                                self.cropped_display = cv2.cvtColor(curr_crop, cv2.COLOR_BGR2RGB)
                                self.cropped_display = Image.fromarray(self.cropped_display)
                                self.cropped_display = ImageTk.PhotoImage(self.cropped_display)
                                self.curr_canvas2.configure(width=curr_crop.shape[1], height=curr_crop.shape[0])
                                self.curr_canvas2.create_image(0, 0, image=self.cropped_display, anchor=tk.NW)
                                self.curr_canvas2.image = self.cropped_display

                                self.curr_time2.delete(1.0, tk.END)
                                self.curr_time2.insert(tk.INSERT, "time: ")
                                self.curr_time2.insert(tk.END, str(round(self.peg_end2/1000,ndigits=4))+' sec ('+str(int(self.peg_end2/1000//60))+' min '+str(round(self.peg_end2/1000%60,ndigits=1))+' sec)')    
                            
                            print("heart rates:",self.heart_rates)
                            if len(self.heart_rates) == 0:
                                self.heart_rate_text = str(-1)
                                mean_hr = 0
                                self.min_hr = 0
                                self.max_hr = 0
                            elif len(self.heart_rates) > 0:
                                for hr in self.heart_rates:
                                    if hr > 50:
                                        self.filtered_hrs.append(hr)
                                mean_hr = np.mean(self.filtered_hrs)
                                self.min_hr = np.min(self.filtered_hrs)
                                self.max_hr = np.max(self.filtered_hrs)                     
                            
                            if v.get() == 0:
                                # display final heart rates, time taken
                                self.hr_final_text.insert(tk.END, str(self.filtered_hrs)+"\n")
                                self.time_final_text.insert(tk.END, str(round(self.timed, 4))+"\n")
                                
                            self.output.extend([[str(self.count), str(round(self.peg_start2/1000,4)), str(round(self.peg_end2/1000,4)),str(round((self.peg_end2-self.peg_start2)/1000,4)), str(self.min_hr),str(self.max_hr),str(round(mean_hr,3))]])
                            
                            self.heart_rates = []
                            self.filtered_hrs = []
                            self.count += 1

                    # ------------------------------------------------
                    # conditions for end
                    # ------------------------------------------------
                    if (self.starting==True and self.ssim_curr>0.8) and ((self.delta_curr-self.delta_prev1<0 and self.delta_prev1-self.delta_prev2<=0 and self.delta_prev2-self.delta_prev3<=0) and ((self.ssim_curr>self.ssim_prev1 and (self.ssim_curr-self.ssim_prev2>=0 or self.ssim_prev2-self.ssim_prev3>0.6))) or (self.delta_curr<=self.delta_prev1 and self.delta_prev1<=self.delta_prev2 and self.ssim_curr>self.ssim_prev1 and self.ssim_prev1>self.ssim_prev2)):
                        self.peg_end2 = self.video.get_time()
                        self.timed = (self.peg_end2 - self.peg_start2)/1000
                        # ignore contacts of duration less than 5 seconds
                        if round(self.timed,4) >= 5:
                            print("-----END------")
                            self.starting = False
                            self.first_start = False
                            start_conditions = False
                            end_conditions = False                        
                            
                            if v.get() == 0:
                                self.cropped_display = cv2.cvtColor(heart_rate, cv2.COLOR_BGR2RGB)
                                self.cropped_display = Image.fromarray(self.cropped_display)
                                self.cropped_display = ImageTk.PhotoImage(self.cropped_display)
                                self.hr_canvas2.configure(width=heart_rate.shape[1], height=heart_rate.shape[0])
                                self.hr_canvas2.create_image(0, 0, image=self.cropped_display, anchor=tk.NW)
                                self.hr_canvas2.image = self.cropped_display
                                
                                
                                self.hr_text2.delete(1.0, tk.END)
                                self.hr_text2.insert(tk.INSERT, "END: ")
                                self.hr_text2.insert(tk.END, self.heart_rate_text)
                                    
                                self.hr_time2.delete(1.0, tk.END)
                                self.hr_time2.insert(tk.INSERT, "time: ")
                                self.hr_time2.insert(tk.END, str(round(self.peg_end2/1000,ndigits=4))+' sec ('+str(int(self.peg_end2/1000//60))+' min '+str(round(self.peg_end2/1000%60,ndigits=1))+' sec)')    
                                
                                self.cropped_display = cv2.cvtColor(curr_crop, cv2.COLOR_BGR2RGB)
                                self.cropped_display = Image.fromarray(self.cropped_display)
                                self.cropped_display = ImageTk.PhotoImage(self.cropped_display)
                                self.curr_canvas2.configure(width=curr_crop.shape[1], height=curr_crop.shape[0])
                                self.curr_canvas2.create_image(0, 0, image=self.cropped_display, anchor=tk.NW)
                                self.curr_canvas2.image = self.cropped_display

                                self.curr_time2.delete(1.0, tk.END)
                                self.curr_time2.insert(tk.INSERT, "time: ")
                                self.curr_time2.insert(tk.END, str(round(self.peg_end2/1000,ndigits=4))+' sec ('+str(int(self.peg_end2/1000//60))+' min '+str(round(self.peg_end2/1000%60,ndigits=1))+' sec)')    
                            
                            print("heart rates:",self.heart_rates)
                            if len(self.heart_rates) == 0:
                                self.heart_rate_text = str(-1)
                                mean_hr = 0
                                self.min_hr = 0
                                self.max_hr = 0
                            elif len(self.heart_rates) > 0:
                                for hr in self.heart_rates:
                                    if hr > 50:
                                        self.filtered_hrs.append(hr)
                                mean_hr = np.mean(self.filtered_hrs)
                                self.min_hr = np.min(self.filtered_hrs)
                                self.max_hr = np.max(self.filtered_hrs)                     
                            
                            if v.get() == 0:
                                # display final heart rates, time taken
                                self.hr_final_text.insert(tk.END, str(self.filtered_hrs)+"\n")
                                self.time_final_text.insert(tk.END, str(round(self.timed, 4))+"\n")
                            
                            self.output.extend([[str(self.count), str(round(self.peg_start2/1000,4)), str(round(self.peg_end2/1000,4)),str(round((self.peg_end2-self.peg_start2)/1000,4)), str(self.min_hr),str(self.max_hr),str(round(mean_hr,3))]])
                            
                            self.heart_rates = []
                            self.filtered_hrs = []
                            self.count += 1

                    # reset time if misfound
                    if self.ssim_prev3-self.ssim_curr>0.6:
                        print("-----START------")
                        self.starting = True
                        self.peg_start2 = self.video.get_time() 
                        self.first_start = False
                
                elif self.starting==False:
                    # ------------------------------------------------
                    # conditions for start
                    # ------------------------------------------------                
                    if (self.starting==False and self.delta_curr>50 and self.ssim_curr<0.2) and ((self.delta_curr-self.delta_prev1>=0 and self.delta_prev1-self.delta_prev2>0) and (self.ssim_curr-self.ssim_prev1<=0 and self.ssim_curr-self.ssim_prev2<0)) or ((self.delta_curr>=self.delta_prev1 and self.delta_prev1>=self.delta_prev2) and (round(self.ssim_curr,2)<round(self.ssim_prev1,2) and round(self.ssim_curr,2)<self.ssim_prev2)):
                        print("-----START------")
                        self.starting = True
                        self.peg_start2 = self.video.get_time()  
                        self.first_start = False                

                # for testing while running
                # print(">> delta:: curr: {}, prev1: {},  prev2: {}".format(self.delta_curr, self.delta_prev1, self.delta_prev2))
                # print(">>> ssim:: curr: {}, prev1: {},  prev2: {}".format(self.ssim_curr, self.ssim_prev1, self.ssim_prev2))
            
                # update window
                if self.starting==True:   
                    try:
                        self.video.offset_frame_pos(self.offset)
                    except:
                        pass
                else:
                    self.video.offset_frame_pos(self.offset//2)
                
                self.frame_count += 1
                
                # update time on canvas
                time = str(int(self.video.get_time()/1000//60))+' min '+str(round(self.video.get_time()/1000%60,2))+' sec'
                self.canvas.create_text(self.current.shape[1]-100,self.current.shape[0]-20,fill="white",font=self.myFont,text=time)

                self.window.after(15,self.update)

            # end cropped
        # reached end of video frames
        else:
            print("end of video reached.")
            print("output to write: ",self.output)
            root.bind("q", lambda x: root.destroy())  
            video = video_path.split("/")[-1]
            with open('./'+video.split('.')[0]+'.csv','w',newline='') as csvfile:
                f = csv.writer(csvfile)
                f.writerow(['Video:',video])
                f.writerow(['Iteration','TIME_START [sec]','TIME_END [sec]','DURATION [sec]','MIN_HR [bpm]','MAX_HR [bpm]','AVG_HR [bpm]'])
                for i in range(len(self.output)):
                    f.writerow(self.output[i])
            
            # clean up temporary files    
            if os.path.exists("./heart_rate.jpg"):
                os.remove("./heart_rate.jpg")
                
            # update canvas to blue to indicate finish (to blue)
            alpha = 0.01

            self.new_frame = resize_frame(self.new_frame)
            self.new_frame = self.magnify(self.new_frame, 1000)
            self.current = self.new_frame
            h, w = self.current.shape[0:2]
            cv2.rectangle(self.current, self.roi_pt1, self.roi_pt2, color=(255,0,0), thickness=5)
            cv2.addWeighted(self.current, alpha, self.current, 1 - alpha, 0, self.current)
            self.cropped_display = cv2.cvtColor(self.current, cv2.COLOR_BGR2RGB)
            self.cropped_display = Image.fromarray(self.cropped_display)
            self.cropped_display = ImageTk.PhotoImage(self.cropped_display)
            self.canvas.configure(width=w, height=h)
            self.canvas.create_image(0, 0, image=self.cropped_display, anchor=tk.NW)
            self.canvas.image = self.cropped_display
            
            # alert upon end
            messagebox.showinfo("Information", "Ended. \n [Press 'q' to close]")
    # end update
        
    # ---------MAIN: process utility functions------------
    def masking(self, frame):
        # HSV
        l_h, l_s, l_v, u_h, u_s, u_v = [12, 0, 0, 255, 135, 117]
        hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
        l_b = np.array([l_h, l_s, l_v])
        u_b = np.array([u_h, u_s, u_v])
        mask = cv2.inRange(hsv, l_b, u_b)
        masked = cv2.bitwise_and(frame, frame, mask=mask)
        frame = cv2.cvtColor(masked, cv2.COLOR_HSV2BGR)
        return frame
    def get_contours(self, image):
        # grayscale conversion
        grayscaled = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        # threshold
        rett, grayscaled = cv2.threshold(grayscaled, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
        # find contours
        contours, hierarchy = cv2.findContours(grayscaled, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
        return contours
    def compare_images(self, imageA, imageB):
        # compute the mean squared error and structural similarity
        # index for the images
        similarity = ssim(imageA, imageB)
        results = {'ssim': similarity}
        return results
    def magnify(self, frame, scale):
        height, width = frame.shape[0:2]
        r = scale / width # scale/width
        dim = (int(width*r), int(height*r))
        frame = cv2.resize(frame, dim, interpolation=cv2.INTER_AREA)
        return frame
# end Main 

# ---------other utility functions------------
def crop_frame(frame, x1,y1,x2,y2):
    return frame[y1:y2,x1:x2]  
        
def resize_frame(frame):
    height, width = frame.shape[0:2]
    frame = cv2.resize(frame, (0,0), interpolation=cv2.INTER_LINEAR, fx=0.5, fy=0.5)
    return frame

def select_video():
    global video_path, root
    path = filedialog.askopenfilename(filetypes=[("MP4 Format", "*.mp4")])
    if len(path) > 0:
        video_path = path
        Main(root, video_path)
# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
if __name__=="__main__":
    # initialize master root window
    root = tk.Tk()
    root.minsize(width=300, height=100)
    video_path = None
    btn1 = tk.Button(root, text="Select a video", command=select_video)
    btn1.pack(side="top", fill="both", expand="yes", padx="10", pady="10")
    
    # options
    v = tk.IntVar()
    tk.Checkbutton(root, text="Display: OFF", variable=v, onvalue = 1, offvalue = 0).pack(anchor="center", side="left")
    
    default_hr = tk.IntVar()
    tk.Checkbutton(root, text="HR: User-Defined", variable=default_hr, onvalue = 1, offvalue = 0).pack(anchor="center", side="left")
    
    root.mainloop()
