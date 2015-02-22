//+------------------------------------------------------------------+
//|                                            Auto_Adjusting_Ma.mq4 |
//|                                               Shaji Kunjumohamed |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Shaji Kunjumohamed"
#property link      ""
#property version   "1.00"
#property strict
#property indicator_chart_window

extern string Ma_Settings = "Settings for MA";
extern string info1 = "Enter what you want your moving";
extern string info2 = "average to be on the 1 Hour chart";

extern int MaPeriod = 21; // Moving average period
extern int MaShift  = 1;  // Moving average shifted on the chart
                          // Shift curve back and forth.

extern int MaMethod  = 0;  // Moving average shifted on the chart
                           // 0 Simple
                           // 1 Exponential
                           // 2 Smoothed
                           // 3 Linear Weighted.

extern int MaAppliedTo  = 1;  // Moving average shifted on the chart
                              // 0 Close
                              // 1 Open
                              // 2 Hign
                              // 3 Low
                              // ...
extern double MAMultipler; 

//+------------------------------------------------------------------+
//| Adjust the MA for different charts
//| The Period() will retun the info on chart the indicator is 
//| dropped. This gives back multiplier.
//+------------------------------------------------------------------+

void MaAdjuster(int period) {

  MAMultipler = (period == 5)  ? 12 : ( 
                (period == 15) ? 4 : (  
                (period == 30) ? 2 : (  
                (period == 60) ? 1 : (  
                (period == 240) ? 0.25 : 0.125))));
}

//+------------------------------------------------------------------+
//| Additional info :
//| Open[2] - Open price of each candle.
//| Close[2]
//| High[2]
//| Time[2]
//| Volume[2]
//| Bars - Number of bars in current chart    
//+------------------------------------------------------------------+

double Ma_Array[]; // Moverage average of every n-th candle in the 
                   // chart

int AdjustedMa;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int OnInit() {

  // Update AdjustedMa
  MaAdjuster(Period());

  // Now the system is working on an Adjusted MA depending on chart.
  AdjustedMa = MaPeriod * MAMultipler;

//--- indicator buffers mapping

  // Ties array to buffer [Buffer number is 0..7]
  // Below is for buffer 0
  SetIndexBuffer(0, Ma_Array);
  SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1, Red);

  // If we have a 20 moving average, we only need to start drawing 
  // the line from 20-th candle only. "AdjustedMa"  - how far
  // from beginning.
  SetIndexDrawBegin(0, AdjustedMa); 

  // Now set the Label of the index in the chart, i.e name it
  SetIndexLabel(0, "Auto Adjusting MA");
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
    // Bars : total number of candles in
    // the chart. 
    // When OnCalculate executes, it 
    // updatates counted bars.
    int counted_bars = IndicatorCounted();

    // Just run the Indicated until there are 0 counted bars.
    if (counted_bars<0) return (-1); 

    // This is to make the loop the run the last one candle
    // coming in over and over again.
    if (counted_bars>1)  counted_bars--;

    int uncounted_bars = Bars - counted_bars;

    // Need to do this iteration *only* for the
    // uncounted bars.

    // Initially this will be done for all the 
    // bars in the chart present and wait for 
    // the tick to come in.

    for (int i=0; i<uncounted_bars; i++) {
      // Calculate moverage average one candle at a time
      Ma_Array[i] = iMA(
         NULL,           // symbol (current chart symbol) 
         0,              // timeframe (current chart)
         AdjustedMa,     // MA averaging period
         MaShift,        // MA shift
         MaMethod,       // averaging method
         MaAppliedTo,    // applied price
         i               // shift - Candle number
                         // we are getting the moving 
                         // of. How many candles ago
                         // you want to get the moving 
                         // average of 
      );
    
    }
 



   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
