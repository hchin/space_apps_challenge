class coord
{
  public float x, y;
  public coord (float x, float y)
  {  
    this.x=x;
    this.y=y;
  }
  
  public void mean_coord(coord co)
  {
     x+=co.x;
     x/=2; 
     y+=co.y;
     y/=2;
  }
  
  public void update_coord(coord co, float alpha)
  {
     x+=alpha*co.x;
     x/=(1+alpha); 
     y+=alpha*co.y;
     y/=(1+alpha);
  }
}

