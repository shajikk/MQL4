//+------------------------------------------------------------------+
//|                                          BollingerBandTrader.mq4 |
//|                                     Copyright 2013, JimDandy1958 |
//|                                         http://jimdandyforex.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, JimDandy1958"
#property link      "http://jimdandyforex.com"


   extern double LotSize=0.01;
   extern double StopLoss=30;
   extern double TakeProfit=30;
   extern int BollingerPeriod=20;
   extern int BollingerDeviation=2;
   extern int  Fast_Macd_Ema=21;
   extern int  Slow_Macd_Ema=89;
   extern double Macd_Threshold=50;
   double pips;
   extern int MagicNumber=1234;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init() {
      double ticksize = MarketInfo(Symbol(), MODE_TICKSIZE);
   	if (ticksize == 0.00001 || ticksize == 0.001)
	   pips = ticksize*10;
	   else pips =ticksize;
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit() {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start() {
//----
      if(IsNewCandle()) CheckForBollingerBandTrade();
//----
   return(0);
  }
//+------------------------------------------------------------------+

void CheckForBollingerBandTrade() {
   double Macd_Value=iMACD(NULL,0,Fast_Macd_Ema,Slow_Macd_Ema,1,PRICE_CLOSE,MODE_MAIN,1);
   double threshold=Macd_Threshold*pips;
   double MiddleBB=iBands(NULL,0,BollingerPeriod,BollingerDeviation,0,0,MODE_MAIN,1);
   double LowerBB=iBands(NULL,0,BollingerPeriod,BollingerDeviation,0,0,MODE_LOWER,1);
   double UpperBB=iBands(NULL,0,BollingerPeriod,BollingerDeviation,0,0,MODE_UPPER,1);
   double PrevMiddleBB=iBands(NULL,0,BollingerPeriod,BollingerDeviation,0,0,MODE_MAIN,2);
   double PrevLowerBB=iBands(NULL,0,BollingerPeriod,BollingerDeviation,0,0,MODE_LOWER,2);
   double PrevUpperBB=iBands(NULL,0,BollingerPeriod,BollingerDeviation,0,0,MODE_UPPER,2);

   if(Macd_Value>0&&Macd_Value < threshold)
      if(Close[1]>LowerBB&&Close[2]<PrevLowerBB)OrderEntry(0);
   if(Macd_Value<0&&Macd_Value > -threshold)
      if(Close[1]<UpperBB&&Close[2]>PrevUpperBB)OrderEntry(1);
}
//+------------------------------------------------------------------------------

void OrderEntry(int direction) {
   if(direction==0) {
      double tp=Ask+TakeProfit*pips;
      double sl=Ask-StopLoss*pips;
      if(OpenOrdersThisPair(Symbol())==0)
      int buyticket = OrderSend(Symbol(),OP_BUY,LotSize,Ask,3,0,0,NULL,MagicNumber,0,Green);
      if(buyticket>0)OrderModify(buyticket,OrderOpenPrice(),sl,tp,0,CLR_NONE);
   }
   
   if(direction==1) {
      tp=Bid-TakeProfit*pips;
      sl=Bid+StopLoss*pips;
      if(OpenOrdersThisPair(Symbol())==0)
      int sellticket = OrderSend(Symbol(),OP_SELL,LotSize,Bid,3,0,0,NULL,MagicNumber,0,Red);
      if(sellticket>0)OrderModify(sellticket,OrderOpenPrice(),sl,tp,0,CLR_NONE);
   }

}

//+------------------------------------------------------------------+
//checks to see if any orders open on this currency pair.
//+------------------------------------------------------------------+
int OpenOrdersThisPair(string pair) {
  int total=0;
   for(int i=OrdersTotal()-1; i >= 0; i--)
	  {
      OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      if(OrderSymbol()== pair) total++;
	  }
	  return (total);
}

//+------------------------------------------------------------------+
//insuring its a new candle function
//+------------------------------------------------------------------+
bool IsNewCandle() {
   static int BarsOnChart=0;
	if (Bars == BarsOnChart)
	return (false);
	BarsOnChart = Bars;
	return(true);
}

//+------------------------------------------------------------------+

