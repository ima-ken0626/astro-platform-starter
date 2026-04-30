#property strict
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_color1 Aqua
#property indicator_color2 Lime
#property indicator_color3 Orange
#property indicator_color4 Silver

input int AdxPeriod = 14;
input int StdFastPeriod = 26;
input int StdSlowPeriod = 52;

double AdxMain[], StdFast[], StdSlow[], TrendinessFlag[];

int OnInit(){
   IndicatorBuffers(4);
   SetIndexBuffer(0, AdxMain); SetIndexBuffer(1, StdFast); SetIndexBuffer(2, StdSlow); SetIndexBuffer(3, TrendinessFlag);
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1);
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1);
   SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 1);
   SetIndexStyle(3, DRAW_HISTOGRAM, STYLE_SOLID, 2);
   IndicatorShortName("MegaTrendFollow_v2_subwindow");
   return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[]){
   for(int i=rates_total-1;i>=0;i--){
      AdxMain[i] = iADX(NULL,0,AdxPeriod,PRICE_CLOSE,MODE_MAIN,i);
      StdFast[i] = iStdDev(NULL,0,StdFastPeriod,0,MODE_SMA,PRICE_CLOSE,i);
      StdSlow[i] = iStdDev(NULL,0,StdSlowPeriod,0,MODE_SMA,PRICE_CLOSE,i);
      bool ok = (i+1<rates_total) && (AdxMain[i]>AdxMain[i+1]) && (StdFast[i]>StdFast[i+1]) && (StdFast[i]>=StdSlow[i]);
      TrendinessFlag[i] = ok ? 1.0 : 0.0;
   }
   return(rates_total);
}
