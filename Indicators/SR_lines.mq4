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



double         pips;
extern int     SR_band=5;
extern int     window=7;
extern int     max_samples=5;
extern color   Clr=Magenta;

#include "PA_lib/BaseClass.mq4"
#include "PA_lib/Config.mq4"

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int OnInit() {

   cfg.set_pips();

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {


  int size=ArraySize(cfg.chartObj);

  for (int i = 0; i<=size-1; i++) {
    ObjectDelete(cfg.chartObj[i]);
  }

}

//+------------------------------------------------------------------+
//| Time series element
//+------------------------------------------------------------------+
#include "PA_lib/TS_Element.mq4"

//+------------------------------------------------------------------+
//| Parse time series
//+------------------------------------------------------------------+
#include "PA_lib/ParseTS/ParseTS.mq4"

#include "PA_lib/ParseTS/Support.mq4"

#include "PA_lib/ParseTS/Resistance.mq4"

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

ParseTS hourly; 

bool flag = false;

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
    // Bars : total number of candles in the chart. 
    static int BarsOnChart = 0; // Initialized once.

    if (BarsOnChart == 0) {
      Print("== Info : Number of 1 hr candles = " + Bars);
      Print("== Info : Number of 4 hr candles = " + Bars/4);
      Print("== Info : Number of days = " + Bars/24);

      // Hourly candle
      for (int i=Bars-1; i>1; i--) {
        hourly.process_candle(i);
      }

      // 4hr candle

    } else if (BarsOnChart != 0 && Bars != BarsOnChart) {

        // Hourly candle
        hourly.process_candle(1);
    }
    

    BarsOnChart = Bars;

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
