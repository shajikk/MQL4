//+------------------------------------------------------------------+
//|                                    AutoLotsizingEAStochastic.mq4 |
//|                                               Shaji Kunjumohamed |
//+------------------------------------------------------------------+

#property copyright "Shaji Kunjumohamed"
#property version   "1.00"
#property strict


// How much above or below the candle we want the stop to trail.
// Sell side above, Buy side below.
extern int PadAmount = 20;

extern int CandlesBack = 5;

// What percent are u willing to risk ?
extern double RiskPercent = 5;

extern double reward_ratio=2; 

extern int FastMA            = 21;

extern int SlowMA            = 89;


extern int MaximumStopDistance=50;

extern int  Fast_Macd_Ema=21;

extern int  Slow_Macd_Ema=89;

extern double Macd_Threshold=50;


extern int  PercentK=5;
extern int  PercentD=3;
extern int  Slowing=3;

extern int MagicNumber   = 1234;

int FastMaShift       = 0;
int FastMaMethod      = 0;
int FastMaAppliedTo   = 0;
                         
int SlowMaShift       = 0;
int SlowMaMethod      = 0;
int SlowMaAppliedTo   = 0;

double pips;

/* F4 button will toggle between meta trader and meta editor */ 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   
  // Auto adjust for a 4 digit or a 5 digit broker.
  // Get the ticksize of this broker, depending on pair.
  double ticksize = MarketInfo(Symbol(), MODE_TICKSIZE); 

  // To support older platform, where ticksize == pips
  pips = (ticksize == 0.00001 || ticksize == 0.001) ?  ticksize*10 : ticksize;
   
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
  if(IsNewCandle()) CheckForStochasticMacdTrade();
}

//+------------------------------------------------------------------+
//| IsNewCandle generic function
//+------------------------------------------------------------------+
bool IsNewCandle() {
  static int BarsOnChart = 0; // Initialized once.
                              // Only available in this scope. 
                              // Self contained.
  // Bars is a new candle.
  // multiple ticks in same candle.

  if (Bars == BarsOnChart) return(false);
  BarsOnChart = Bars;
  return(true); 
}
//+------------------------------------------------------------------+
//| There can be trades on multiple pairs going on. The OrderEntry
//| function's OrdersTotal is going to return info on all the 
//| currencypair orders. Ideally, we just want the currency pair 
//| this EA is working on. The below function does that.
//+------------------------------------------------------------------+
int OpenOrdersThisPair(string pair) {
  int total = 0;
  for (int i=OrdersTotal()-1; i>=0; i--) {
   OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
   if (OrderSymbol() == pair) total++;
  }
  return total;
} 

//+------------------------------------------------------------------+
//| OrderEntry generic function
//+------------------------------------------------------------------+

void OrderEntry(int direction) {  

    double Equity = AccountEquity();
    double RiskedAmount = Equity * RiskPercent * 0.01;

    int buyStopCandle =  iLowest(
       NULL,            // symbol
       0,               // timeframe 5, 15 , 1hr chart
       MODE_LOW,        // timeseries id
       CandlesBack,     // n candles, including 0-th
       1                // start from candle 1
    );
   
    int  sellStopCandle = iHighest(
       NULL,            // symbol
       0,               // timeframe
       MODE_HIGH,       // timeseries id
       CandlesBack,     // n candles, including 0-th
       1                // start from candle 1
    );


    double buy_stop_price  = Low[buyStopCandle] - PadAmount*pips; // Lowest low
    double pips_to_bsl = Ask - buy_stop_price;
    double buy_takeprofit_price = Ask + pips_to_bsl * reward_ratio;

    double sell_stop_price = High[sellStopCandle] + PadAmount*pips; // Highest highest 
    double pips_to_ssl = sell_stop_price-Bid;
    double sell_takeprofit_price = Bid - pips_to_ssl * reward_ratio;



    double LotSize;

    // Buy, Crossed Up : 
    if(direction==0 && pips_to_bsl/pips<MaximumStopDistance) {

      double bsl=buy_stop_price;
      double btp=buy_takeprofit_price;
      
      // Important..
      //LotSize = (100/(0.00500/0.00010))/10;
      LotSize = (RiskedAmount/(pips_to_bsl/pips))/10;

      // This can be any number. Eg. 3. We limit to 3 orders per currency pair.
      if (OpenOrdersThisPair(Symbol()) == 0) { // No more on going trade.

         // Fix for ECN broker.
         int ticket = OrderSend(
           Symbol(),            // symbol, string, Put the exact . 
           OP_BUY,              // operation, int, (OP_BUY=0, OP_SELL=1)      
           LotSize,             // volume, double   
           Ask,                 // price, double, Market order   

           3,                   // slippage, int      
                                // From the time we hit button, until
                                // the order gets filled it can 
                                // move one way or other. Helps
                                // in fast moving market.

           0, // has to be 0    // stop loss, double, actual price   
                                // eg. For buying it can be 25 pips
                                // Less than asking price.
                                // StopLoss multiplier need to be adjusted
                                // to currency (Point)

           0, // has to be zero // take profit, double   
           NULL,                // Put a comment on the trade, string   

           MagicNumber,         // magic number, int      
                                // More than one EA on EURUSD
                                // and keep their trades seperate
                                // from each other. Kind of ID
                                // number on which expert advisor placed
                                // this particular trade. Each of these
                                // EAs need to go through all trades and
                                // and figure out which trade are theres
                                // and act on those. 
                           
           0,                   // pending order expiration, datetime 
                                // 0 - not a pnding order

           Green                // color, It will draw the green arrow
         );

         if (ticket > 0) { 

           OrderModify(
             ticket,
             OrderOpenPrice(),
             bsl,
             btp, 
             0,
             CLR_NONE 
           );

         }

      }
    }
   
    // Sell, Crossed down : 
    if(direction==1 && pips_to_ssl/pips<MaximumStopDistance) {

      double ssl=sell_stop_price;
      double stp=sell_takeprofit_price;
      LotSize = (RiskedAmount/(pips_to_ssl/pips))/10;

      // This can be any number. Eg. 3. We limit to 3 orders per currency pair.
      if (OpenOrdersThisPair(Symbol()== 0)) {  // No more on going trade.

         // Manipulation for ECN broker
         int ticket = OrderSend(
           Symbol(),
           OP_SELL,
           LotSize,
           Bid,
           3,
           0,  // Has to be 0
           0,  // Has to be zero
           NULL,
           MagicNumber,
           0,
           Red
         );


         if (ticket > 0) { 

           OrderModify(
             ticket,
             OrderOpenPrice(),
             ssl,
             stp, 
             0,
             CLR_NONE 
           );

         }
      }
    }
}

//+------------------------------------------------------------------+
//| Do trade generic function
//+------------------------------------------------------------------+

void CheckForStochasticMacdTrade()
{
   double Macd_Value=iMACD(NULL,0,Fast_Macd_Ema,Slow_Macd_Ema,1,PRICE_CLOSE,MODE_MAIN,1);
   double threshold=Macd_Threshold*pips;
   double K_Line=iStochastic(NULL,0,PercentK,PercentD,Slowing,0,0,MODE_MAIN,1);
   double D_Line=iStochastic(NULL,0,PercentK,PercentD,Slowing,0,0,MODE_SIGNAL,1);
   double Previous_K_Line=iStochastic(NULL,0,PercentK,PercentD,Slowing,0,0,MODE_MAIN,2);
   double Previous_D_Line=iStochastic(NULL,0,PercentK,PercentD,Slowing,0,0,MODE_SIGNAL,2);

   if (Macd_Value>-threshold)  { 
     if(Previous_K_Line > 80 && Previous_D_Line > 80) {
        if(Previous_K_Line > Previous_D_Line && K_Line < D_Line) OrderEntry(1);
     }
   }

   if (Macd_Value<threshold)   {
     if(Previous_K_Line < 20 && Previous_D_Line < 20) {
        if(Previous_K_Line < Previous_D_Line && K_Line > D_Line) OrderEntry(0);
     }
   }
}

//+------------------------------------------------------------------+
