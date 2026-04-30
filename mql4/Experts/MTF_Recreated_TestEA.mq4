#property strict

input double RiskPercent = 1.0;
input int MagicNumber = 26043001;
input int Slippage = 10;
input double MaxSpreadPoints = 30;
input bool UseTrendinessFilter = true;
input bool CloseOnly = true;
input int TrendPeriod = 50;
input ENUM_MA_METHOD BaseMethod = MODE_SMA;
input int ATRPeriod = 14;
input double ATRMultiplier = 3.3;

static datetime g_lastBarTime = 0;

bool IsNewBar(){
   datetime t = iTime(Symbol(), Period(), 0);
   if(t != g_lastBarTime){ g_lastBarTime = t; return true; }
   return false;
}

double CalcLotByRisk(double stopDistance){
   if(stopDistance <= 0) return 0;
   double riskMoney = AccountEquity() * (RiskPercent/100.0);
   double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double tickSize  = MarketInfo(Symbol(), MODE_TICKSIZE);
   if(tickValue <= 0 || tickSize <= 0) return 0;
   double moneyPerPointPerLot = tickValue / tickSize;
   double lots = riskMoney / (stopDistance * moneyPerPointPerLot);
   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double step   = MarketInfo(Symbol(), MODE_LOTSTEP);
   if(step <= 0) step = 0.01;
   lots = MathFloor(lots/step)*step;
   lots = MathMax(minLot, MathMin(maxLot, lots));
   return NormalizeDouble(lots, 2);
}

int CurrentPositionType(){
   for(int i=OrdersTotal()-1;i>=0;i--){
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber){
            if(OrderType()==OP_BUY) return OP_BUY;
            if(OrderType()==OP_SELL) return OP_SELL;
         }
      }
   }
   return -1;
}

bool CloseAllPositions(){
   bool ok=true;
   for(int i=OrdersTotal()-1;i>=0;i--){
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber){
            bool r=false;
            if(OrderType()==OP_BUY)  r=OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, clrRed);
            if(OrderType()==OP_SELL) r=OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, clrYellow);
            ok = ok && r;
         }
      }
   }
   return ok;
}

void UpdateTrailingStop(){
   double atr = iATR(NULL,0,ATRPeriod,1);
   if(atr<=0) return;
   for(int i=OrdersTotal()-1;i>=0;i--){
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=MagicNumber) continue;
      if(OrderType()==OP_BUY){
         double newSL = NormalizeDouble(Bid - atr*ATRMultiplier, Digits);
         if(OrderStopLoss()==0 || newSL > OrderStopLoss())
            OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrRed);
      }
      if(OrderType()==OP_SELL){
         double newSL = NormalizeDouble(Ask + atr*ATRMultiplier, Digits);
         if(OrderStopLoss()==0 || newSL < OrderStopLoss())
            OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrYellow);
      }
   }
}

bool TrendinessOk(){
   if(!UseTrendinessFilter) return true;
   double adx0 = iADX(NULL,0,14,PRICE_CLOSE,MODE_MAIN,1);
   double adx1 = iADX(NULL,0,14,PRICE_CLOSE,MODE_MAIN,2);
   double sd26_0 = iStdDev(NULL,0,26,0,MODE_SMA,PRICE_CLOSE,1);
   double sd26_1 = iStdDev(NULL,0,26,0,MODE_SMA,PRICE_CLOSE,2);
   double sd52_0 = iStdDev(NULL,0,52,0,MODE_SMA,PRICE_CLOSE,1);
   return (adx0 > adx1) && (sd26_0 > sd26_1) && (sd26_0 >= sd52_0);
}

int SignalDirection(){
   int shift = CloseOnly ? 1 : 0;
   double cur = iCustom(NULL,0,"MegaTrendFollow_v2",TrendPeriod,BaseMethod,PRICE_CLOSE,CloseOnly,30,0,shift);
   double dwn = iCustom(NULL,0,"MegaTrendFollow_v2",TrendPeriod,BaseMethod,PRICE_CLOSE,CloseOnly,30,1,shift);
   if(cur != EMPTY_VALUE) return 1;
   if(dwn != EMPTY_VALUE) return -1;
   return 0;
}

void OpenPosition(int dir){
   double atr = iATR(NULL,0,ATRPeriod,1);
   if(atr<=0) return;
   double stopDistance = atr * ATRMultiplier;
   double lots = CalcLotByRisk(stopDistance);
   if(lots<=0) return;

   double price = dir==1 ? Ask : Bid;
   double sl = dir==1 ? price-stopDistance : price+stopDistance;
   sl = NormalizeDouble(sl, Digits);
   int type = dir==1 ? OP_BUY : OP_SELL;
   OrderSend(Symbol(), type, lots, price, Slippage, sl, 0, "MTF_Recreated", MagicNumber, 0, dir==1?clrRed:clrYellow);
}

int OnInit(){
   Print("MTF EA ready: bar-close doten + ATR risk sizing");
   return(INIT_SUCCEEDED);
}

void OnTick(){
   double spreadPoints = (Ask - Bid) / Point;
   if(spreadPoints > MaxSpreadPoints) return;

   UpdateTrailingStop();
   if(!IsNewBar()) return;

   int sig = SignalDirection();
   if(sig==0 || !TrendinessOk()) return;

   int pos = CurrentPositionType();
   if((sig==1 && pos==OP_BUY) || (sig==-1 && pos==OP_SELL)) return;

   CloseAllPositions();
   OpenPosition(sig);
}
