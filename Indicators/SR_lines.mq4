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
extern color   Clr=Magenta;

//+------------------------------------------------------------------+
//| Config class
//+------------------------------------------------------------------+

class SR_config {

  public:
    double  pips;
    double  half_band;
    void    set_pips(void);
};

void SR_config::set_pips(void) {

  // Get the ticksize of this broker, depending on pair.
  double ticksize = MarketInfo(Symbol(), MODE_TICKSIZE); 

  // To support older platform, where ticksize == pips
  this.pips = (ticksize == 0.00001 || ticksize == 0.001) ?  ticksize*10 : ticksize;

  this.half_band = (SR_band/2) * this.pips;
  Print("Test");
}

SR_config cfg;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int OnInit() {

   cfg.set_pips();

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Time series element
//+------------------------------------------------------------------+
class TS_Element {

  public:
    datetime t;
    double upper_limit;
    double lower_limit;
    double value;
    int    weight;
    void   fix_bands(void);
};


void TS_Element::fix_bands(void) {
    this.upper_limit = this.value + cfg.half_band;
    this.lower_limit = this.value - cfg.half_band;
}

//+------------------------------------------------------------------+
//| Parse time series
//+------------------------------------------------------------------+

class ParseTS {

  public:
    TS_Element* current;
    TS_Element* previous;
    TS_Element* TS_sparse[];
    bool    previous_already_added;
    void    first_parse(int limit);
    void    Mark_resistance(void);
    void    push_sparse(TS_Element* element);
    void    compare(void);

    ParseTS() { this.previous_already_added = false; };
};

void ParseTS::push_sparse(TS_Element* element) {
  int size=ArraySize(this.TS_sparse);
  ArrayResize(this.TS_sparse, size+1);
  this.TS_sparse[size] = element;
  //size=ArraySize(this.TS_sparse);
  //Print("size = " + size + "\n");
}


void ParseTS::Mark_resistance() {
  int size=ArraySize(this.TS_sparse);

  for (int i = 0; i<=size-1; i++) {
    TS_Element* element = this.TS_sparse[i]; 
    Print("loc = " + i + "\n");
    Print("t = " +  TimeToStr(element.t, TIME_DATE|TIME_MINUTES) + "\n");
    Print("val = " + element.value + "\n");
    ObjectCreate("p_"+i, OBJ_ARROW_DOWN,0,element.t, element.value);
    ObjectSet("p_"+i, OBJPROP_COLOR, Clr);
  }

}

void ParseTS::compare(void) {

  // condition for skipping current

   /*
     prev ul -------------
                
                       ---------------  curr ul  |
                                                 | 
     prev ll -------------                       |
                                                 |
                       ---------------  curr ll  |
   */


   /*
     curr ul -------------
                
                       ---------------  prev ul  |
                                                 | 
     curr ll -------------                       |
                                                 |
                       ---------------  prev ll  |
   */

   if (
       (this.current.upper_limit >= this.previous.lower_limit &&
        this.current.lower_limit <= this.previous.lower_limit) ||

       (this.previous.upper_limit >= this.current.lower_limit &&
        this.previous.lower_limit <= this.current.lower_limit)) {
     this.previous = this.current;
     return;
   } 


   /*
                       ---------------  curr ul  



                       ---------------  curr ll  

     prev ul -------------

                
                                                  
     prev ll -------------                       
   */

   if (this.current.lower_limit > this.previous.upper_limit) {
     this.previous_already_added = false;
     this.previous = this.current;
     return;
   } 

   /*
     ---------------  prev ul  



     ---------------  prev ll  

                         curr ul -------------

                
                                                  
                         curr ll -------------                       
   */
   if (this.current.upper_limit < this.previous.lower_limit) {
     //this.check_previous();
     if (!this.previous_already_added) this.push_sparse(this.previous);
     this.previous = this.current;
     this.previous_already_added = true;
   } 

}

void ParseTS::first_parse(int limit) {

    for (int i=limit-1; i>=0; i--) {

      if ((i % 7) == 0 && (limit-1 - i) > (7+1)) {

        double highest;
        int i_track;
        datetime t;

        /*  Example
        i=22
        i=21 => 22 23 24 25 26 27 28  <= i+1+7-1                         
        i=14 => 15 16 17 18 19 20 21
        i=7  =>  8  9 10 11 12 13 14   
        i=0  =>  1  2  3  4  5  6  7 
        */

        for (int j = i+1; j<= (i+1+7-1) ; j++) {
          double sample = (Close[j] > Open[j]) ? Close[j] : Open[j];

          if (j == i+1) {
            highest = sample;           
            i_track = j;           
            t = Time[j];           
          }

          highest = (sample > highest) ? sample : highest;
          i_track = (sample > highest) ? j : i_track;
          t       = (sample > highest) ? Time[j] : t;
        }

        //Print("highest = " + highest + " Num = " + i_track + "\n");
        this.current = new TS_Element();
        
       
        this.current.value = highest;
        this.current.t = t;
        this.current.fix_bands();

        if (this.previous != NULL) {
          this.compare();
        } else {
          // current becomes previous
          this.previous = this.current;
        }

      } // if
      
    } // for

}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

ParseTS pts; 

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
    // Bars : total number of candles in
    // the chart. 
    // When OnCalculate executes, it 
    // updatates counted bars.
    int counted_bars = IndicatorCounted();

    // Error check
    if (counted_bars<0) return (-1); 

    // This is to make the loop the run the last one candle
    // coming in over and over again.

    int limit = Bars - counted_bars;


    if (limit == 1) {
    
      // to do      

    } else {
      pts.first_parse(limit);
      pts.Mark_resistance();
    }



   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
