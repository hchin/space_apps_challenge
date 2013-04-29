/**
 @file SSAC_misson_control
 @detail simulates orbital nadir view for the lego rover
 
 */

import codeanticode.gsvideo.*;
GSCapture cam;

int cam_w=960, cam_h=720;
int cur_cam_r, cur_cam_delta;
int cam_rad;
PImage cur_cam;
PFont myFont;
int mark_x, mark_y;
int zoom_x, zoom_y;
long mission_time;
int prev_s;

int qx, qy;

int sat_mode;

coord bot_coord; 
coord goal_coord;
coord acquire_coord;
float acquire_rad;

color bot_color, goal_color;
float color_dist;
float goal_dist = -1;
boolean cheat_mode;
boolean found_goal;


//tracker
int MAX_TRACKER = 2;
int cur_track = 0;
Tracker[] track_list;

void setup() 
{
  size(960, 960);

  cam = new GSCapture(this, cam_w, cam_h, "/dev/video0");
  cam.start();

  myFont = createFont("mono-48.vlw", 32);
  cur_cam_r = 0;
  cur_cam_delta = 100;
  cur_cam = new PImage(cam_w, cam_h); 
  cam_rad = 200;
  sat_mode = 0;

  bot_color = color(180, 80, 40);
  goal_color = color(60, 100, 40);
  color_dist = 30;
  cursor(CROSS);

  track_list = new Tracker[MAX_TRACKER];
}

void keyPressed()
{
  switch(key)
  {
  case 'c': 
    cheat_mode = !cheat_mode;
    println("cheat: "+cheat_mode);
    break;
  case 'w':
    cur_cam_delta++;
    break;
  case 's':
    cur_cam_delta--;
    break;
  case 'a':
    if (sat_mode!=2)
    {  
      sat_mode = 2;
      track_list = new Tracker[MAX_TRACKER];
      cur_track = 0;
    }
    else 
    {
      sat_mode =0;
      acquire_coord =null;
    }
    break;
  }
}

void mouseReleased()
{


  if (sat_mode==2)
  {
    if (cur_track<MAX_TRACKER)
    {
      track_list[cur_track] = new Tracker(cur_track, cam, acquire_coord, acquire_rad);
      cur_track++;
    }
    else
      println("Max number of tracks reached!");
  }
}

void mouseDragged()
{
  if (sat_mode==2)
  {
    if (acquire_coord!=null)
    {
      float rad_x = (abs(mouseX-acquire_coord.x));
      float rad_y = (abs(mouseY-acquire_coord.y));
      acquire_rad = max(rad_x, rad_y);

      acquire_rad = min(dist(0, 0, acquire_coord.x, acquire_coord.y), acquire_rad);
      acquire_rad = min(acquire_coord.x, acquire_rad);
      acquire_rad = min(acquire_coord.y, acquire_rad);
    }
  }
}
void mousePressed()
{
  if (mouseButton==LEFT)
  {
    if (sat_mode==1)
    {
      mark_x = mouseX;
      mark_y = mouseY;
    }

    if (sat_mode==0)
    {
      qx = mouseX;
      qy = mouseY; 
      int ind = (qy-1)*cam_w+qx;
      color c = cam.pixels[ind];
      println(String.format("%f %f %f", red(c), green(c), blue(c)));
    }

    if (sat_mode ==2)
    {
      acquire_coord = new coord(mouseX, mouseY);
    }
  }

  if (mouseButton==RIGHT)
  {
    sat_mode = (sat_mode+1)%2;
    if (sat_mode==0)
    {
      mark_x = -1;
      mark_y = -1;
    }
    if (sat_mode==1)
    {
      zoom_x = max(cam_rad, mouseX);
      zoom_x = min(zoom_x, cam_w-cam_rad);
      zoom_y = max(cam_rad, mouseY);
      zoom_y = min(zoom_y, cam_h-cam_rad);
    }
  }
}
void draw() 
{
  background(0);
  if (cam.available()) 
  {
    cam.read();

    for (int i=0; i<cur_track; i++)
    {
      track_list[i].track(cam);
    }

    switch(sat_mode)
    {
    case 0:   
      {
        cam.loadPixels();
        cur_cam.loadPixels();
        //forms the current image
        for (int r=0; r<cur_cam_delta; r++)
        {
          for (int c=0; c<cam_w; c++)
          {
            int ind = cur_cam_r*cam_w+c;
            cur_cam.pixels[ind] = cam.pixels[ind];
          }
          cur_cam_r = (cur_cam_r+1)%cam_h;
        }
        cur_cam.updatePixels();

        if (!cheat_mode) cur_cam.filter(GRAY); //simulate grayscale imaging
      }
      break;
    case 1:
      cur_cam.copy(cam, zoom_x-cam_rad, zoom_y-cam_rad, 2*cam_rad, 2*cam_rad, 0, 0, cam_w, cam_h);
      break;
    case 2:
      {
        cur_cam.copy(cam, 0, 0, cam_w, cam_h, 0, 0, cam_w, cam_h);
      }
    }
  }

  image(cur_cam, 0, 0);

  if (sat_mode==0)
  {
    draw_scan_aux();
    draw_tracker();
  }
  if (sat_mode==2)
  {
    if (acquire_coord!=null)
    {
      stroke(0);
      strokeWeight(2);
      ellipse(acquire_coord.x, acquire_coord.y, 2*acquire_rad, 2*acquire_rad);
      draw_tracker();
    }
  }

  if (goal_coord != null)
  {
    stroke(0, 0, 255);
    strokeWeight(5);
    point(goal_coord.x, goal_coord.y);
    noFill();
    strokeWeight(1);
    ellipse(goal_coord.x, goal_coord.y, 40, 40);
    point(goal_coord.x, goal_coord.y);
  }

  display_stats();
}

void draw_tracker()
{
  for (int i=0; i<cur_track; i++)
    track_list[i].draw_track();
}

void draw_scan_aux()
{


  stroke(40, 200, 20);
  strokeWeight(2);
  line(0, cur_cam_r, cam_w, cur_cam_r);

  if (bot_coord != null)
  {
    stroke(255, 0, 0);
    strokeWeight(5);
    point(bot_coord.x, bot_coord.y);
    noFill();
    strokeWeight(1);
    ellipse(bot_coord.x, bot_coord.y, 120, 120);
  }
}

void scan_tgts()
{
  coord cur_bot_coord = get_loc_color(bot_color, null, 20);
  coord cur_goal_coord = get_loc_color(goal_color, new coord(200, 400), 30);
  if (bot_coord==null)
    bot_coord = cur_bot_coord;
  else
    if (cur_bot_coord!=null)
      bot_coord.update_coord(cur_bot_coord, 0.1);
    else
      bot_coord = null;
  if (goal_coord==null)
    goal_coord = cur_goal_coord;
  else
    if (cur_goal_coord!=null)
      goal_coord.update_coord(cur_goal_coord, 0.1);
    else
      goal_coord = null;

  if (goal_coord!=null && bot_coord!=null)
    goal_dist = dist(goal_coord.x, goal_coord.y, bot_coord.x, bot_coord.y); 
  else
    goal_dist = -1;

  if (goal_dist>0 && goal_dist<200 && !found_goal)
  {
    found_goal = true;
  }
}

coord get_loc_color(color to_track, coord ex_co, float dist_thresh)
{
  float totx = 0;
  float toty = 0;
  int totc = 0;

  float track_r = red(to_track);
  float track_g = green(to_track);
  float track_b = blue(to_track);

  for (int i=0; i<cam.pixels.length; i++)
  {
    color cur = cam.pixels[i];
    float r = red(cur);
    float g = green(cur);
    float b = blue(cur);
    if (dist(r, g, b, track_r, track_g, track_b)< dist_thresh)
    {

      int x = i%cam_w;
      int y = (i-x)/cam_w+1;
      if (ex_co!=null)
      {
        if (dist(ex_co.x, ex_co.y, x, y)>100)
          continue;
      }
      totc++;
      totx +=x;
      toty +=y;
    }
  }
  if (totc>0)
  {
    totx/=totc;
    toty/=totc;
    return new coord(totx, toty);
  }
  else
    return null;
}



void display_stats()
{
  textFont(myFont, 36);
  textAlign(LEFT);
  fill(0, 200, 0);
  int d = day();    // Values from 1 - 31
  int m = month();  // Values from 1 - 12
  int y = year();  
  int s = second();  // Values from 0 - 59
  int ms = minute();  // Values from 0 - 59
  int h = hour();  

  if (s!=prev_s)
  {
    prev_s = s;
    mission_time++;
  }

  String date_str = String.format("MISSION DATE: %d:%d:%d %d:%d:%d", y, m, d, h, ms, s);
  String elapse_str = String.format("MISSION ELAPSE: %d s", mission_time);
  textAlign(LEFT);
  text(date_str, 10, 760);
  text(elapse_str, 10, 810);


  noFill(); 
  strokeWeight(2);
  textFont(myFont, 36);
  String mode_str = "";
  switch(sat_mode)
  {
  case 0:
    {
      stroke(40, 200, 20);
      mode_str = "WIDE\nLINESCAN";
    }
    break;

  case 1:
    {
      stroke(255, 0, 0);
      mode_str = "CLOSEIN\nZOOM";
    }
    break;
  case 2:
    {
      stroke(0, 0, 255);
      mode_str = "ACQUIRE\nTRACK";
    }
    break;
  }
  textAlign(CENTER);
  text(mode_str, 800, 760);
  rect(690, 725, 220, 100);
}


boolean sketchFullScreen() 
{
  return true;
}

