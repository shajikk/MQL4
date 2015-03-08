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
extern int     window=5;
extern int     max_samples=5;

extern int     base_chart_period=30;
extern bool    spawn_child_chart=true;

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
//| CombineTS, Root
//+------------------------------------------------------------------+

#include "PA_lib/CombineTS.mq4"

#include "PA_lib/Root.mq4"

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

bool flag = false;

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
    static int BarsOnChart = 0; // Initialized once.

    if (Period() != base_chart_period) {
      return(rates_total);
    }

    if (BarsOnChart == 0) {
      Print("== Info : Number of 1 hr candles = " + Bars);
      Print("== Info : Number of 4 hr candles = " + Bars/4);
      Print("== Info : Number of days = " + Bars/24);

      rt.push_array("30m", rt.TS_chart_name);
      rt.push_array("1hr", rt.TS_chart_name);
      rt.push_array("4hr", rt.TS_chart_name);
      rt.push_array("day", rt.TS_chart_name);
      rt.Init();

      for (int i=Bars-1; i>1; i--) {

        TS_Element* buf;
        buf = new TS_Element();
        buf.set_fields(High[i], Low[i], Open[i], Close[i], Time[i]);

        rt.Iterate_charts(buf);
        delete(buf);

      }

    } else if (BarsOnChart != 0 && Bars != BarsOnChart) {


        TS_Element* buf;
        buf = new TS_Element();
        buf.set_fields(High[1], Low[1], Open[1], Close[1], Time[1]);

        rt.Iterate_charts(buf);
        delete(buf);

    }
    

    BarsOnChart = Bars;

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
