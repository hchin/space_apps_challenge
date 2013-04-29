class Tracker
{

  coord cg;
  int id;


  int cstep = 5;
  int clevels = 255/cstep+1;
  float alpha = 0.3;
  float rad; 
  int rad2;

  int win = 10;
  int [][] color_bins;
  color track_color;

  public Tracker (int id, PImage scene, coord tgt_loc, float rad)
  {
    
    this.id=id;
    println("new tracker: id ="+id);
    learn(scene, tgt_loc, rad);
    cg = tgt_loc;
    this.rad = rad;
    rad2 = (int)(2*rad);
    track_color = color( (int)(random(255)), (int)(random(255)), (int)(random(255)));
    
  }

  public void draw_track()
  {
    stroke(track_color);
    strokeWeight(2);
    ellipse(cg.x, cg.y, 2*rad, 2*rad);
    point(cg.x, cg.y);
  }


  public void learn(PImage scene, coord loc, float rad)
  {
    int rad2 = (int)(2*rad);
    PImage im = new PImage(rad2, rad2);
    im.copy(scene, (int)(loc.x-rad), (int)(loc.y-rad), rad2, rad2, 0, 0, rad2, rad2);
    
     
    color_bins = bin_image(im);
    println(color_bins[0]);
    println(color_bins[1]);
    println(color_bins[2]);
    println("track acquired");
  }

  public int [][] bin_image(PImage im)
  {
    int [][] bins = new int[3][clevels];
    im.loadPixels();
    //println("pix len"+im.pixels.length);
    for (int i=0; i< (im.pixels).length; i++)
    {
      int r = (int)red(im.pixels[i]);
      int g = (int)green(im.pixels[i]);
      int b = (int)blue(im.pixels[i]);
      //println(r+":"+g+":"+b);
      bins[0][r/cstep]++;
      bins[1][g/cstep]++;
      bins[2][b/cstep]++;
    }
    return bins;
  }

  public void track(PImage scene)
  {
    PImage testimg = new PImage(rad2, rad2);
    float cgx=-1, cgy=-1;
    int startx = win;
    int starty = win;
    int endx = scene.width-win;
    int endy = scene.height-win;
    startx = max(startx, (int)cg.x-win);
    starty = max(starty, (int)cg.y-win);
    endx = min(endx, (int)cg.x+win);
    endy = min(endy, (int)cg.y+win);

    int best_score = Integer.MAX_VALUE;
    for (int x=startx; x<endx; x++)
      for (int y=starty; y<endy; y++)
      {
        testimg.copy(scene, x-win, y-win, 2*win, 2*win, 0, 0, rad2, rad2);
        int [][] cur_bin = bin_image(testimg);
        int cur_score = score_bin(cur_bin);
        if (cur_score < best_score)
        {
        //  println(cur_score);
          best_score = cur_score;
          cgx = x; 
          cgy =y ;
        }
      }


    if (cgx>=0 && cgy>=0)
    {
      cg.x = (1-alpha)*cg.x+alpha*cgx;
      cg.y = (1-alpha)*cg.y+alpha*cgy;
    }
  }

  public int score_bin(int [][] cur_bin)
  {
    int score = 0;
    for (int i=0; i<color_bins.length; i++)
      for (int j=0; j<color_bins[0].length; j++)
        score += abs(color_bins[i][j] - cur_bin[i][j]);
    return score;
  }
}

