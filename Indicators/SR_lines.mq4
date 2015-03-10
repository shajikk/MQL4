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

extern bool    spawn_child_chart=true;

int     base_chart_period=PERIOD_M30;

#include "PA_lib/BaseClass.mq4"
#include "PA_lib/Config.mq4"

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
//| CombineTS, Root
//+------------------------------------------------------------------+

#include "PA_lib/CombineTS.mq4"

#include "PA_lib/Root.mq4"

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

Root  rt;

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

    if (Period() != base_chart_period) {
      return(rates_total);
    }

    rt.Iterate_charts();

//--- return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int OnInit() {

   if (Period() != base_chart_period) {
     return(INIT_SUCCEEDED);
   }

   cfg.set_pips();
   rt.push_array("30m", rt.TS_chart_name);
   rt.push_array("1hr", rt.TS_chart_name);
   rt.push_array("4hr", rt.TS_chart_name);
   rt.push_array("day", rt.TS_chart_name);
   rt.Init();

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {


  int size=ArraySize(cfg.chartObj);
  rt.Deinit();

  for (int i = 0; i<=size-1; i++) {
    ObjectDelete(cfg.chartObj[i]);
  }

}

//+------------------------------------------------------------------+
