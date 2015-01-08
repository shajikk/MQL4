//+------------------------------------------------------------------+
//|                                            Moving_Average_EA.mq4 |
//|                                               Shaji Kunjumohamed |
//+------------------------------------------------------------------+
#property copyright "Shaji Kunjumohamed"
#property version   "1.00"
#property strict

extern int TakeProfit    = 50;
extern int StopLoss      = 25;

extern int FastMA            = 5;
extern int FastMaShift       = 0;
extern int FastMaMethod      = 0;
extern int FastMaAppliedTo   = 0;
                         
extern int SlowMA            = 21;
extern int SlowMaShift       = 0;
extern int SlowMaMethod      = 0;
extern int SlowMaAppliedTo   = 0;

extern double LotSize    = 0.01;

extern int MagicNumber   = 123;

double pips;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---
   
  // Get the ticksize of this broker, depending on pair.
  double ticksize = MarketInfo(Symbol(), MODE_TICKSIZE); 

  // To support older platform, where ticksize == pips
  pips = (ticksize == 0.00001 || ticksize == 0.001) ?
    ticksize*10 : ticksize;
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
  if (IsNewCandle()) CheckForMaTrade();
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
//| OrderEntry generic function
//+------------------------------------------------------------------+

void OrderEntry(int direction) {  

    // Important : Need to do below only once per candle. Multiple
    // ticks can come in per candle for this chart.
    // OrdersTotal will take care of that.

    // Has the fast one has crossed over to slow one ? 

    // Buy, Crossed Up : 
    if (direction == 0) {
      if (OrdersTotal() == 0) { // No more on going trade.

         OrderSend(
           Symbol(),            // symbol, string, Put the exact . 
           OP_BUY,              // operation, int, (OP_BUY=0, OP_SELL=1)      
           LotSize,             // volume, double   
           Ask,                 // price, double, Market order   

           3,                   // slippage, int      
                                // From the time we hit button, until
                                // the order gets filled it can 
                                // move one way or other. Helps
                                // in fast moving market.

           Ask-(StopLoss*pips), // stop loss, double, actual price   
                                // eg. For buying it can be 25 pips
                                // Less than asking price.
                                // StopLoss multiplier need to be adjusted
                                // to currency (Point)

           Ask+(TakeProfit*pips),  // take profit, double   
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

      }
    }
   
    // Sell, Crossed down : 
    if (direction == 1) {
      if (OrdersTotal() == 0) {  // No more on going trade.
         OrderSend(
           Symbol(),
           OP_SELL,
           LotSize,
           Bid,
           3,
           Bid+(StopLoss*pips),
           Bid-(TakeProfit*pips),
           NULL,
           MagicNumber,
           0,
           Red
         );
      }
    }
}

//+------------------------------------------------------------------+
//| Do trade generic function
//+------------------------------------------------------------------+

void CheckForMaTrade() { 

    // Use candle 1. Candle 0 is always changing. Candle 1
    // stable.

    // Fast
    double PreviousFast = iMA( NULL, 0, FastMA, FastMaShift, FastMaMethod,
         FastMaAppliedTo, 2
      );
    double CurrentFast  = iMA( NULL, 0, FastMA, FastMaShift, FastMaMethod,
         FastMaAppliedTo, 1
      );


    // Slow
    double PreviousSlow =iMA( NULL, 0, SlowMA, SlowMaShift, SlowMaMethod,
         SlowMaAppliedTo, 2
      );
    double CurrentSlow =iMA( NULL, 0, SlowMA, SlowMaShift, SlowMaMethod,
         SlowMaAppliedTo, 1
      );


    // Important : Need to do below only once per candle. Multiple
    // ticks can come in per candle for this chart.
    // OrdersTotal will take care of that.

    // Has the fast one has crossed over to slow one ? 

    // Buy, Crossed Up : 
    if (PreviousFast < PreviousSlow && CurrentFast> CurrentSlow) {
      OrderEntry(0);
    }
   
    // Sell, Crossed down : 
    if (PreviousFast > PreviousSlow && CurrentFast <  CurrentSlow) {
      OrderEntry(1);
    }
}
//+------------------------------------------------------------------+
