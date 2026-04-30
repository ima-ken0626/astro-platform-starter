#property strict
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 Red
#property indicator_color2 Yellow
#property indicator_color3 Red
#property indicator_color4 Yellow

input int                TrendPeriod       = 50;
input ENUM_MA_METHOD     BaseMethod        = MODE_SMA;
input ENUM_APPLIED_PRICE PriceType         = PRICE_CLOSE;
input bool               CloseOnly         = true;
input int                ArrowOffsetPoints = 30;

double UpLine[], DownLine[], BuyArrow[], SellArrow[];
double Src[], HalfMA[], FullMA[], RawMA[], Mega[];

double SelectPrice(const int i, const double &open[], const double &high[], const double &low[], const double &close[]){
   switch(PriceType){
      case PRICE_OPEN:     return open[i];
      case PRICE_HIGH:     return high[i];
      case PRICE_LOW:      return low[i];
      case PRICE_MEDIAN:   return (high[i] + low[i]) / 2.0;
      case PRICE_TYPICAL:  return (high[i] + low[i] + close[i]) / 3.0;
      case PRICE_WEIGHTED: return (high[i] + low[i] + close[i] + close[i]) / 4.0;
      default:             return close[i];
   }
}

int OnInit(){
   IndicatorBuffers(4);
   SetIndexBuffer(0, UpLine); SetIndexBuffer(1, DownLine);
   SetIndexBuffer(2, BuyArrow); SetIndexBuffer(3, SellArrow);
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2); SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 2);
   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 1); SetIndexStyle(3, DRAW_ARROW, STYLE_SOLID, 1);
   SetIndexArrow(2, 233); SetIndexArrow(3, 234);
   SetIndexEmptyValue(0, EMPTY_VALUE); SetIndexEmptyValue(1, EMPTY_VALUE);
   SetIndexEmptyValue(2, EMPTY_VALUE); SetIndexEmptyValue(3, EMPTY_VALUE);
   IndicatorShortName("MegaTrendFollow_v2_Recreated");
   return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[], const long &tick_volume[], const long &volume[], const int &spread[]){
   if(rates_total < TrendPeriod + 5) return(0);

   int half = MathMax(1, TrendPeriod / 2);
   int root = MathMax(1, (int)MathRound(MathSqrt(TrendPeriod)));

   ArrayResize(Src, rates_total); ArrayResize(HalfMA, rates_total); ArrayResize(FullMA, rates_total);
   ArrayResize(RawMA, rates_total); ArrayResize(Mega, rates_total);
   ArraySetAsSeries(Src, true); ArraySetAsSeries(HalfMA, true); ArraySetAsSeries(FullMA, true);
   ArraySetAsSeries(RawMA, true); ArraySetAsSeries(Mega, true);

   for(int i=rates_total-1;i>=0;i--){
      UpLine[i]=EMPTY_VALUE; DownLine[i]=EMPTY_VALUE; BuyArrow[i]=EMPTY_VALUE; SellArrow[i]=EMPTY_VALUE;
      Src[i]=SelectPrice(i, open, high, low, close);
   }

   for(int i=rates_total-1;i>=0;i--){
      HalfMA[i]=iMAOnArray(Src, rates_total, half, 0, BaseMethod, i);
      FullMA[i]=iMAOnArray(Src, rates_total, TrendPeriod, 0, BaseMethod, i);
      RawMA[i]=2.0*HalfMA[i]-FullMA[i];
   }
   for(int i=rates_total-1;i>=0;i--) Mega[i]=iMAOnArray(RawMA, rates_total, root, 0, BaseMethod, i);

   int s = CloseOnly ? 1 : 0;
   for(int i=rates_total-(3+s);i>=0;i--){
      bool bull=Mega[i+s]>Mega[i+s+1];
      bool bullPrev=Mega[i+s+1]>Mega[i+s+2];
      if(bull) UpLine[i]=Mega[i+s]; else DownLine[i]=Mega[i+s];
      if(bull && !bullPrev) BuyArrow[i]=low[i]-ArrowOffsetPoints*_Point;
      if(!bull && bullPrev) SellArrow[i]=high[i]+ArrowOffsetPoints*_Point;
   }
   return(rates_total);
}
