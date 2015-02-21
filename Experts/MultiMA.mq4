//+------------------------------------------------------------------+
//|                                                      MultiMA.mq4 |
//|                                               Shaji Kunjumohamed |
//+------------------------------------------------------------------+

#property copyright "Shaji Kunjumohamed"
#property version   "1.00"
#property strict


extern string  s1="Ma_Trail_Settings";

extern bool    Use_MA_Trail=true;
extern int     MA_Period=60;

extern string  s2="Trailing_Stop_Settings";
extern bool    UseTrailingStop=false;
extern int     WhenToTrail=20;
extern int     TrailAmount=10;

extern string  Candle_Trail_Settings="Training stop must also be true";
extern bool    UseCandleTrial=false;

extern string  MoveToBreakeven_Settings="**************************";
extern bool    UseMoveToBreakEven=false;
extern int     WhenToMoveToBE=20;
extern int     PipsToLockIn=3;

extern int     PadAmount=0;
extern int     CandlesBack=5;
extern int     StopCandle=1;

extern double  RiskPercent   = 2;
extern double  RewardRatio   = 2;

extern int     MagicNumber   = 123;

double         pips;
datetime       triggerBarTime;
string         Bias="none";

// ---- Initialization function
int OnInit() {

  // Get the ticksize of this broker, depending on pair.
  double ticksize = MarketInfo(Symbol(), MODE_TICKSIZE); 

  // To support older platform, where ticksize == pips
  pips = (ticksize == 0.00001 || ticksize == 0.001) ?
    ticksize*10 : ticksize;

   return(INIT_SUCCEEDED);
}


// ---- Deinitialization function
void OnDeinit(const int reason) {
   
}

void OnTick() {
  // No need to run function if there are no open orders.
  if (IsNewCandle()) { 
    CheckForMaTrade();

    if (OpenOrdersThisPair(Symbol()) > 0) {
      if (UseMoveToBreakEven)  MoveToBreakeven();
      if (UseTrailingStop)  AdjustTrail();
      if (Use_MA_Trail)  MA_Trail();
    }

  }
}

// F12 button can step through the stratergy tester..

// ---- Main check for trade function
void CheckForMaTrade() {
  double CSF1 = iMA(NULL, 0, 3, 0, 1, 0, 1); // Fastest MA
  double CSF2 = iMA(NULL, 0, 5, 0, 1, 0, 1);
  double CSF3 = iMA(NULL, 0, 8, 0, 1, 0, 1);
  double CSF4 = iMA(NULL, 0, 10, 0, 1, 0, 1);
  double CSF5 = iMA(NULL, 0, 12, 0, 1, 0, 1);
  double CSF6 = iMA(NULL, 0, 15, 0, 1, 0, 1);
 
  double ema21 = iMA(NULL, 0, 21, 0, 1, 0, 1); // Middle line

  double CBF1 = iMA(NULL, 0, 30, 0, 1, 0, 1);
  double CBF2 = iMA(NULL, 0, 35, 0, 1, 0, 1);
  double CBF3 = iMA(NULL, 0, 40, 0, 1, 0, 1);
  double CBF4 = iMA(NULL, 0, 45, 0, 1, 0, 1);
  double CBF5 = iMA(NULL, 0, 50, 0, 1, 0, 1);
  double CBF6 = iMA(NULL, 0, 60, 0, 1, 0, 1); // Slowest MA


  if (  Bias == "none" &&
        CSF1>CSF2 &&
        CSF2>CSF3 &&
        CSF3>CSF4 &&
        CSF4>CSF5 &&
        CSF5>CSF6 &&
        CSF6>CBF1 &&
        CBF1>CBF2 &&
        CBF2>CBF3 &&
        CBF3>CBF4 &&
        CBF4>CBF5 &&
        CBF5>CBF6
  ) {
   
     triggerBarTime = Time[1]; 
     Bias = "up";
     Comment("Bias is: " + Bias + " since " + TimeToStr(triggerBarTime, TIME_DATE|TIME_MINUTES));
  }

  // Buying scenario +
  // Anytime the price gets below 21
  // ... and the close is above 60 moving average..
  if (Bias=="up" && Low[1] < ema21 && Close[1] > CBF6) {
    OrderEntry(0); // Fire trade and set up a pending buy
  }

  // Delete the pending order if Bias is up and 
  // price closes below 60
  if (Bias=="up" && Close[1]<CBF6) {
    DeleteOrder();
    Bias = "none";
    Comment("Bias is: " + Bias + " since " + TimeToStr(triggerBarTime, TIME_DATE|TIME_MINUTES));

  }
 
  if (  Bias == "none" &&
        CSF1<CSF2 &&
        CSF2<CSF3 &&
        CSF3<CSF4 &&
        CSF4<CSF5 &&
        CSF5<CSF6 &&
        CSF6<CBF1 &&
        CBF1<CBF2 &&
        CBF2<CBF3 &&
        CBF3<CBF4 &&
        CBF4<CBF5 &&
        CBF5<CBF6
  ) {
   
     triggerBarTime = Time[1]; 
     Bias = "down";
     Comment("Bias is: " + Bias + " since " + TimeToStr(triggerBarTime, TIME_DATE|TIME_MINUTES));
  }

  // Selling scenario +
  // Anytime the price gets above 21
  // ... and the close is below 60 moving average..
  if (Bias=="down" && High[1] > ema21 && CBF6 > Close[1]) {
    OrderEntry(1); // Fire trade and set up a pending sell
  }

  // If Bias is down and price closes above 60 delete the order
  if (Bias == "down" && Close[1]>CBF6) {
    DeleteOrder();
    Bias = "none";
    Comment("Bias is: " + Bias + " since " + TimeToStr(triggerBarTime, TIME_DATE|TIME_MINUTES));
  }
}


//+------------------------------------------------------------------+
//| OrderEntry function
//+------------------------------------------------------------------+

void OrderEntry(int direction) {  
 
  double LotSize      = 0;
  double Equity       = AccountEquity();
  double RiskedAmount = Equity*RiskPercent*0.01;

  // Returns the candle number where bias was set.
  int iTBT = iBarShift(NULL, 60, triggerBarTime, true);

  // Find highest high.
  int iHH  = iHighest(NULL, 60, MODE_HIGH, iTBT + 1, 0);
  double buyPrice = High[iHH] + PadAmount*pips;

  // Find lowest low
  int iLL  = iLowest(NULL, 60, MODE_LOW, iTBT + 1, 0);
  double sellPrice = Low[iLL] - PadAmount*pips;

  double buy_stop_price = iMA(NULL, 60, 60, 0, 1, 0, 1) - PadAmount*pips;
  double pips_to_bsl    = buyPrice-buy_stop_price;
  double buy_takeprofit_price = (pips_to_bsl*RewardRatio)+buyPrice;

  double sell_stop_price = iMA(NULL, 60, 60, 0, 1, 0, 1) + PadAmount*pips;
  double pips_to_ssl    = sell_stop_price-sellPrice;
  double sell_takeprofit_price = sellPrice-(pips_to_bsl*RewardRatio);

  if (direction==0) { // Buy
    double bsl = buy_stop_price; 
    double btp = buy_takeprofit_price; 
    LotSize = (RiskedAmount/(pips_to_bsl/pips))/10;
    if (OpenOrdersThisPair(Symbol()) == 0) {
      int BuyTicketOrder = OrderSend(Symbol(), OP_BUYSTOP, LotSize, buyPrice, 3, bsl, btp, NULL, MagicNumber, 0, Green);
      if (BuyTicketOrder > 0) {
        Print("Order Placed #", BuyTicketOrder);
      } else {
        Print("Order Send Failed, error #", GetLastError());

      }
    }
  }

  if (direction==1) { // Sell
    double ssl = sell_stop_price; 
    double stp = sell_takeprofit_price; 
    LotSize = (RiskedAmount/(pips_to_ssl/pips))/10;
    if (OpenOrdersThisPair(Symbol()) == 0) {
      int SellTicketOrder = OrderSend(Symbol(), OP_SELLSTOP, LotSize, buyPrice, 3, ssl, stp, NULL, MagicNumber, 0, Red);
      if (SellTicketOrder > 0) {
        Print("Order Placed #", SellTicketOrder);
      } else {
        Print("Order Send Failed, error #", GetLastError());

      }
    }
  }

}
//+------------------------------------------------------------------+
//| DeleteOrder function
//+------------------------------------------------------------------+

void DeleteOrder() {  

  for (int i= OrdersTotal()-1; i>=0; i--) {
    if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue; 
    
    if (OrderMagicNumber() == MagicNumber &&
        OrderSymbol() == Symbol() &&
        OrderType() > OP_SELL) {
       if (!OrderDelete(OrderTicket(), CLR_NONE)) {
         Print("Order Close failed, order number: ", 
                OrderTicket(),
               "Error: ", GetLastError()); 
       }
    }
  }

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
          if (UseCandleTrial) {
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
          if (UseCandleTrial) {
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
//| MA_Trail
//+------------------------------------------------------------------+

void MA_Trail() {

  // Loop through orders.

  // Buy Order
  for (int b=OrdersTotal()-1; b>=0; b--) {
    if (OrderSelect(b, SELECT_BY_POS, MODE_TRADES)) {  
      if (OrderMagicNumber() == MagicNumber) { // This EA ownes it
        // Check the Symbol !!!!   
        if (OrderSymbol() == Symbol() && OrderType() == OP_BUY) {

            if (Use_MA_Trail) {
              if (OrderStopLoss() < iMA(NULL, 0, 60, 0, 1, 0, 0) - PadAmount*pips) {
                OrderModify(
                  OrderTicket(),
                  OrderOpenPrice(),
                  iMA(NULL, 0, 60, 0, 1, 0, 0) - PadAmount*pips,
                  OrderTakeProfit(),
                  0,
                  CLR_NONE
                );
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
            if (Use_MA_Trail) {
              if (OrderStopLoss() > iMA(NULL, 0, 60, 0, 1, 0, 0) + PadAmount*pips) {
                OrderModify(
                  OrderTicket(),
                  OrderOpenPrice(),
                  iMA(NULL, 0, 60, 0, 1, 0, 0) + PadAmount*pips,
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

