#property strict
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 Red
#property indicator_color2 Yellow

input int ATRPeriod = 14;
input double ATRMultiplier = 3.3;

double LongStop[], ShortStop[];

int OnInit(){
   IndicatorBuffers(2);
   SetIndexBuffer(0, LongStop); SetIndexBuffer(1, ShortStop);
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1);
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1);
   SetIndexEmptyValue(0, EMPTY_VALUE); SetIndexEmptyValue(1, EMPTY_VALUE);
   IndicatorShortName("StopATR_v2");
   return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[]){
   int dir = 1;
   double stop = 0.0;
   for(int i=rates_total-1;i>=0;i--){
      double atr = iATR(NULL,0,ATRPeriod,i);
      double lb = close[i] - atr*ATRMultiplier;
      double sb = close[i] + atr*ATRMultiplier;
      if(i==rates_total-1){ dir=1; stop=lb; }
      else {
         if(dir==1){ stop=MathMax(stop, lb); if(close[i]<stop){ dir=-1; stop=sb; } }
         else      { stop=MathMin(stop, sb); if(close[i]>stop){ dir= 1; stop=lb; } }
      }
      LongStop[i]=dir==1 ? stop : EMPTY_VALUE;
      ShortStop[i]=dir==-1 ? stop : EMPTY_VALUE;
   }
   return(rates_total);
}
