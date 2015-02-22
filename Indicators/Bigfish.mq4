//+------------------------------------------------------------------+
//|                                               Bigfish.mq4        |
//|                                               Shaji Kunjumohamed |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Shaji Kunjumohamed"
#property link      ""
#property version   "1.00"
#property strict

#property indicator_chart_window
#property indicator_buffers    6
#property indicator_color1     Lime
#property indicator_color2     Lime
#property indicator_color3     Lime
#property indicator_color4     Lime
#property indicator_color5     Lime
#property indicator_color6     Magenta

//#property indicator_color7     Red

//---- buffers 
double ExtMapBuffer1[];
double ExtMapBuffer2[];
double ExtMapBuffer3[];
double ExtMapBuffer4[];
double ExtMapBuffer5[];
double ExtMapBuffer6[];


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


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int OnInit() {

  SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 1);
  SetIndexBuffer(0, ExtMapBuffer1);
  SetIndexLabel(0, "30 EMA");
  SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1);
  SetIndexBuffer(1, ExtMapBuffer2);
  SetIndexLabel(1, "35 EMA");
  SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 1);
  SetIndexBuffer(2, ExtMapBuffer3);
  SetIndexLabel(2, "40 EMA");
  SetIndexStyle(3, DRAW_LINE, STYLE_SOLID, 1);
  SetIndexBuffer(3, ExtMapBuffer4);
  SetIndexLabel(3, "45 EMA");
  SetIndexStyle(4, DRAW_LINE, STYLE_SOLID, 1);
  SetIndexBuffer(4, ExtMapBuffer5);
  SetIndexLabel(4, "50 EMA");

  SetIndexStyle(5, DRAW_LINE, STYLE_SOLID, 1);
  SetIndexBuffer(5, ExtMapBuffer6);
  SetIndexLabel(5, "60 EMA");

   
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
      ExtMapBuffer1[i] = iMA(NULL, 0, 30, 0, MODE_EMA, PRICE_CLOSE, i); 
      ExtMapBuffer2[i] = iMA(NULL, 0, 35, 0, MODE_EMA, PRICE_CLOSE, i); 
      ExtMapBuffer3[i] = iMA(NULL, 0, 40, 0, MODE_EMA, PRICE_CLOSE, i); 
      ExtMapBuffer4[i] = iMA(NULL, 0, 45, 0, MODE_EMA, PRICE_CLOSE, i); 
      ExtMapBuffer5[i] = iMA(NULL, 0, 50, 0, MODE_EMA, PRICE_CLOSE, i); 
      ExtMapBuffer6[i] = iMA(NULL, 0, 60, 0, MODE_EMA, PRICE_CLOSE, i); 
    }
 



   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
