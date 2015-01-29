//+------------------------------------------------------------------+
//|                                            CandleTraingStop.mq4  |
//|                                               Shaji Kunjumohamed |
//+------------------------------------------------------------------+
#property copyright "Shaji Kunjumohamed"
#property version   "1.00"
#property strict

extern int TakeProfit    = 50;
extern int StopLoss      = 25;

// Whether to use Breakeven.
extern bool UseMoveToBreakeven = true;

// When do we want to move to Breakeven,
// how many pips we ant to get before we breakeven.
extern int WhenToMoveToBE = 100;

// How many pips we want to lock in.
extern int PipsToLockIn=5;

// Do you want to use Trailing stop
extern bool UseTrailingStop = true;
extern int WhenToTrail      = 100;
extern int TrailAmount      = 50; 

// Usage of a candle trailing stop.
extern bool UseCandleTrail = false;

// How much above or below the candle we want the stop to trail.
// Sell side above, Buy side below.
extern int PadAmount = 20;

extern int StopCandle = 1;

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
  if (OpenOrdersThisPair(Symbol()) >= 1) {
    // No need to run function if there are no open orders.
    if (UseMoveToBreakeven)  MoveToBreakeven();
    if (UseTrailingStop)  AdjustTrail();
  }

  if (IsNewCandle()) CheckForMaTrade();
}
//+------------------------------------------------------------------+
//| Breakeven function
//| The break-even stop is enacted when a trader adjusts their stop 
//| to their trade's entry price to remove the initial risk amount 
//| from the trade. After position moves in traders favor, stop
//| is moved up to initial entry. If the price moves beyond this
//| level, the trader will not likely face a loss. "Not making a loss
//| is better than making a profit"
//+------------------------------------------------------------------+
void MoveToBreakeven() {

  // Loop through orders.

  // Buy Order
  for (int b=OrdersTotal()-1; b>=0; b--) {
    if (OrderSelect(b, SELECT_BY_POS, MODE_TRADES)) {  
      if (OrderMagicNumber() == MagicNumber) { // This EA ownes it
        // Check the Symbol !!!!   
        if (OrderSymbol() == Symbol() && OrderType() == OP_BUY) {
          //                          Convert pips to money.
          if (Bid-OrderOpenPrice()  > WhenToMoveToBE*pips) {
            if (OrderOpenPrice() > OrderStopLoss()) {  // Stop loss is 
                                                       // already not moved,
                                                       // move it, else next
                                                       // order.
              OrderModify(
                OrderTicket(),                             // ticket
                OrderOpenPrice(),                          // price
                
                // Breakeven price
                OrderOpenPrice() + (PipsToLockIn*pips),    // stop loss
                OrderTakeProfit(),                         // take profit
                0,                                         // expiration
                CLR_NONE                                   // color
              );
            } 
          }
        }
      }
    }
  }

  // Sell trade
  for (int s=OrdersTotal()-1; s>=0; s--) {
    if (OrderSelect(s, SELECT_BY_POS, MODE_TRADES)) {  
      if (OrderMagicNumber() == MagicNumber) {
        if (OrderSymbol() == Symbol() && OrderType() == OP_SELL) {
          if (OrderOpenPrice()-Ask  > WhenToMoveToBE*pips) { // How far it has fallen
            if (OrderOpenPrice() < OrderStopLoss()) { // If stop loss is not 
                                                      // moved yet, move it
              OrderModify(
                OrderTicket(),
                OrderOpenPrice(),

                // Breakeven for sell
                OrderOpenPrice() - (PipsToLockIn*pips),
                OrderTakeProfit(),
                0, CLR_NONE
              );
            } 
          }
        }
      }
    }
  }

} 
//+------------------------------------------------------------------+
//| Trailing Stop
//+------------------------------------------------------------------+

void AdjustTrail() {

  // Loop through orders.

  // Buy Order
  for (int b=OrdersTotal()-1; b>=0; b--) {
    if (OrderSelect(b, SELECT_BY_POS, MODE_TRADES)) {  
      if (OrderMagicNumber() == MagicNumber) { // This EA ownes it
        // Check the Symbol !!!!   
        if (OrderSymbol() == Symbol() && OrderType() == OP_BUY) {

          // Fork, do it only for a new candle for this
          // time frame.
          if (UseCandleTrail && IsNewCandle()) {
            if (OrderStopLoss() < Low[StopCandle] - PadAmount*pips) {
              OrderModify(OrderTicket(), OrderOpenPrice(), 
              Low[StopCandle] - PadAmount*pips,
              OrderTakeProfit(), 0, CLR_NONE);
            } 
          } else {

            //                          Convert pips to money.
            if (Bid-OrderOpenPrice()  > WhenToTrail*pips) {
              if (OrderStopLoss() < Bid-pips*TrailAmount) {  // Check whether the trail
                                                             // has already been moved,
                OrderModify(
                  OrderTicket(),                             // ticket
                  OrderOpenPrice(),                          // price
                  
                  // Shift stop loss up
                  Bid-(pips*TrailAmount),                    // stop loss
                  OrderTakeProfit(),                         // take profit
                  0,                                         // expiration
                  CLR_NONE                                   // color
                );
              } 
            }

          }
        }
      }
    } 
  } // Iterate over orders

  // Sell trade
  for (int s=OrdersTotal()-1; s>=0; s--) {
    if (OrderSelect(s, SELECT_BY_POS, MODE_TRADES)) {  
      if (OrderMagicNumber() == MagicNumber) {
        if (OrderSymbol() == Symbol() && OrderType() == OP_SELL) {

          // Fork Like buy side
          if (UseCandleTrail && IsNewCandle()) {
            if (OrderStopLoss() < High[StopCandle] + PadAmount*pips) {
              OrderModify(OrderTicket(), OrderOpenPrice(), 
              High[StopCandle] + PadAmount*pips,
              OrderTakeProfit(), 0, CLR_NONE);
            }
          } else {

            if (OrderOpenPrice()-Ask  > WhenToMoveToBE*pips) { // How far it has fallen
              if (OrderStopLoss() > Ask+TrailAmount*pips || 
                  OrderStopLoss() == 0 ) { // If stop loss is not 
                                           // moved yet, move it, else ignore
                                           // Now, if somebody puts StopLoss 0
                                           // (not using stop loss)
                                           // sell side never trails,
                                           // stop loss never kicks in. 
                                           // (Buy side is ok)
                                           // Put that condition here. 
                OrderModify(
                  OrderTicket(),
                  OrderOpenPrice(),
            
                  // Breakeven for sell
                  Ask+(TrailAmount*pips),
                  OrderTakeProfit(),
                  0, CLR_NONE
                );
              } 
            }
          }
        }
      }
    }
  }




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

    // Important : Need to do below only once per candle. Multiple
    // ticks can come in per candle for this chart.
    // OrdersTotal will take care of that.

    // Has the fast one has crossed over to slow one ? 

    // Buy, Crossed Up : 
    if (direction == 0) {

      // Take care of condition where somebody puts stop loss to 0
      double bsl = (StopLoss == 0) ? 0 : Ask-(StopLoss*pips);

      // Take care of condition where somebody puts take profit 0
      double btp = (TakeProfit == 0) ? 0 : Ask+(TakeProfit*pips);

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
    if (direction == 1) {

      // Take care of condition where somebody puts stop loss to 0
      double ssl =  (StopLoss == 0) ? 0 : Bid+(StopLoss*pips);

      // Take care of condition where somebody puts take profit 0
      double stp = (TakeProfit == 0) ? 0 : Bid-(TakeProfit*pips);

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
