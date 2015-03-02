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
extern color   Clr=Magenta;

//+------------------------------------------------------------------+
//| Base class for all other derive classes.
//+------------------------------------------------------------------+


class SR_Base {

  public:
    template<typename T>
    void    push_array(T element, T &arr[]);

    template<typename T>
    T pop_array(T &arr[]);

    template<typename T>
    T pop0_array(T &arr[]);

    template<typename T>
    int check_array_size(T &arr[]);
 
    template<typename T>
    void deleteN0_array(T &arr[], int n);

    template<typename T>
    void debug_array(T &arr[]);

    template<typename T>
    void overwrite_last_element(T element, T &arr[]);

    template<typename T>
    T SR_Base::get_last_element(T &arr[]);

};

template<typename T>
void SR_Base::push_array(T element, T &arr[]) {
  int size=ArraySize(arr);
  ArrayResize(arr, size+1);
  arr[size] = element;
}

template<typename T>
T SR_Base::pop_array(T &arr[]) {

  int size=ArraySize(arr);

  if (size != 0) {
    T element = arr[size-1];
    ArrayResize(arr, size-1);
    return  element;
  }
  return NULL;
  
}

template<typename T>
T SR_Base::pop0_array(T &arr[]) {

  int size=ArraySize(arr);

  if (size != 0) {
    ArraySetAsSeries(arr, true);
    T element = arr[size-1];
    ArrayResize(arr, size-1);
    ArraySetAsSeries(arr, false);
    return  element;
  }
  return NULL;
  
}


template<typename T>
  void SR_Base::deleteN0_array(T &arr[], int n) {

  int size=ArraySize(arr);

  if (size != 0 && n <= size) {
    ArraySetAsSeries(arr, true);
    ArrayResize(arr, size-n);
    ArraySetAsSeries(arr, false);
  }
  
}


template<typename T>
  int SR_Base::check_array_size(T &arr[]) {
  return ArraySize(arr);
}


template<typename T>
  void SR_Base::overwrite_last_element(T element, T &arr[]) {
  int size =  ArraySize(arr);
  if (size > 0) {
    delete arr[size-1];
    arr[size-1] = element;
  }
}


template<typename T>
  T SR_Base::get_last_element(T &arr[]) {
  int size =  ArraySize(arr);
  if (size > 0) {
    return arr[size-1];
  }
  return NULL;
}


// ------ Function for testing ------
template<typename T>
void SR_Base::debug_array(T &arr[]) {

  int size=ArraySize(arr);
  for (i = 0; i < size; i++) {
    Print("DEBUG idx = " + i + " Value = " + arr[i] + "\n"); 
  }

}

//+------------------------------------------------------------------+
//| Config class
//+------------------------------------------------------------------+

class SR_config : public SR_Base {

  public:
    double  pips;
    double  band_value;
    void    set_pips(void);
    string  chartObj[];
   
};

void SR_config::set_pips(void) {

  // Get the ticksize of this broker, depending on pair.
  double ticksize = MarketInfo(Symbol(), MODE_TICKSIZE); 

  if (ticksize == 0.00001 || ticksize == 0.001) {
    this.pips = ticksize*10;
  } else {
    this.pips = ticksize; 
  }

  this.band_value = SR_band * this.pips;
}

SR_config cfg;

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
class TS_Element {

  public:
    datetime t;
    double Open;
    double Close;
    double High;
    double Low;

    double upper_limit;
    double lower_limit;
    double value;
    int    weight;
    void   set_fields(double h, double l, double o, double c, datetime dt);
};

void TS_Element::set_fields(double h, double l, double o, double c, datetime dt) {
    this.Open  = o;
    this.Close = c;
    this.High  = h;
    this.Low   = l;
    this.t     = dt;
}

//+------------------------------------------------------------------+
//| Parse time series
//+------------------------------------------------------------------+

class ParseTS : public SR_Base {

  public:
    TS_Element* r_current;
    TS_Element* r_previous;
    TS_Element* r_buffer[];

    TS_Element* s_current;
    TS_Element* s_previous;
    TS_Element* s_buffer[];

    TS_Element* TS_r_sparse[];
    TS_Element* TS_s_sparse[];
    bool    r_already_added;
    bool    s_already_added;
    void    first_parse(int limit);
    void    calc_resistance(int i);
    void    calc_support(int i);
    void    Mark_resistance(void);
    void    Mark_support(void);
    void    compare_resistance(void);
    void    compare_support(void);
    
    ParseTS() { 
      this.r_already_added = false; 
      this.s_already_added = false; 
    };

};

void ParseTS::Mark_resistance() {
  int size=ArraySize(this.TS_r_sparse);

  for (int i = 0; i<=size-1; i++) {
    TS_Element* element = this.TS_r_sparse[i]; 
    //Print("loc = r_" + i +  "; val = " + element.value + "\n");
    //Print("t = " +  TimeToStr(element.t, TIME_DATE|TIME_MINUTES) + "\n");
    ObjectCreate("r_"+i, OBJ_ARROW_DOWN,0,element.t, element.value);
    ObjectSet("r_"+i, OBJPROP_COLOR, Clr);
    cfg.push_array("r_"+i, cfg.chartObj);
  }
}

void ParseTS::Mark_support() {
  int size=ArraySize(this.TS_s_sparse);

  for (int i = 0; i<=size-1; i++) {
    TS_Element* element = this.TS_s_sparse[i]; 
    //Print("loc = s_" + i +  "; val = " + element.value + "\n");
    //Print("t = " +  TimeToStr(element.t, TIME_DATE|TIME_MINUTES) + "\n");
    ObjectCreate("s_"+i, OBJ_ARROW_UP,0,element.t, element.value);
    ObjectSet("s_"+i, OBJPROP_COLOR, Clr);
    cfg.push_array("s_"+i, cfg.chartObj);
  }
}

void ParseTS::compare_support(void) {

   double delta = MathAbs(this.s_current.value - this.s_previous.value);

   if (delta < cfg.band_value) {
     if (this.s_current.value < this.s_previous.value) {
       this.s_previous = this.s_current;
       return;
     }
   }

   if (delta > cfg.band_value) {

     if (this.s_current.value < this.s_previous.value) {
       this.s_previous = this.s_current;
       this.s_already_added = false;
       return;
     }

     if (this.s_current.value > this.s_previous.value) {
       if (!this.s_already_added) {
         this.push_array(this.s_previous, this.TS_s_sparse); 
       }
       this.s_already_added = true;
       this.s_previous = this.s_current;
       return;
     }
   } 
}

void ParseTS::compare_resistance(void) {

   double delta = MathAbs(this.r_current.value - this.r_previous.value);

   if (delta < cfg.band_value) {
     if (this.r_current.value > this.r_previous.value) {
       this.r_previous = this.r_current;
       return;
     }
   }

   if (delta > cfg.band_value) {

     if (this.r_current.value > this.r_previous.value) {
       this.r_previous = this.r_current;
       this.r_already_added = false;
       return;
     }

     if (this.r_current.value < this.r_previous.value) {
       if (!this.r_already_added) {
         this.push_array(this.r_previous, this.TS_r_sparse); 
       }
       this.r_already_added = true;
       this.r_previous = this.r_current;
       return;
     }
   } 
}

void ParseTS::calc_resistance(int i) {

      TS_Element* buf;
      buf = new TS_Element();
      buf.set_fields(High[i], Low[i], Open[i], Close[i], Time[i]);
      this.push_array(buf, this.r_buffer); 

      int size = this.check_array_size(this.r_buffer);

      if (size == window) {

        double highest = 0.0;
        int sample = 0;


        for (int j = 0; j < size; j++) {

          if (this.r_buffer[j].Close > this.r_buffer[j].Open) {
            this.r_buffer[j].value = this.r_buffer[j].Close;
          } else {
            this.r_buffer[j].value = this.r_buffer[j].Open;
          } 

          // Initialize
          if (j == 0) { 
            highest = this.r_buffer[j].value;
            sample  = 0;
          }

          if (this.r_buffer[j].value > highest) {
            highest = this.r_buffer[j].value;
            sample = j;
          }

        }

         
        for (int j = 0; j < size; j++) {
          if (j != sample) {
            delete this.r_buffer[j];
          }  
        } 

        this.r_current = this.r_buffer[sample];
        ArrayResize(r_buffer, 0); // Clear array memory


        if (this.r_previous != NULL) {
          this.compare_resistance();
        } else {
          // r_current becomes r_previous
          this.r_previous = this.r_current;
        }

      } // check for  buff size
}

void ParseTS::calc_support(int i) {

      TS_Element* buf;
      buf = new TS_Element();
      buf.set_fields(High[i], Low[i], Open[i], Close[i], Time[i]);
      this.push_array(buf, this.s_buffer); 

      int size = this.check_array_size(this.s_buffer);

      if (size == window) {

        double lowest = 0.0;
        int sample = 0;


        for (int j = 0; j < size; j++) {

          if (this.s_buffer[j].Close > this.s_buffer[j].Open) {
            this.s_buffer[j].value = this.s_buffer[j].Open;
          } else {
            this.s_buffer[j].value = this.s_buffer[j].Close;
          } 

          // Initialize
          if (j == 0) { 
            lowest = this.s_buffer[j].value;
            sample  = 0;
          }

          if (this.s_buffer[j].value < lowest) {
            lowest = this.s_buffer[j].value;
            sample = j;
          }

        }

         
        for (int j = 0; j < size; j++) {
          if (j != sample) {
            delete this.s_buffer[j];
          }  
        } 

        this.s_current = this.s_buffer[sample];
        ArrayResize(s_buffer, 0); // Clear array memory


        if (this.s_previous != NULL) {
          this.compare_support();
        } else {
          // s_current becomes s_previous
          this.s_previous = this.s_current;
        }

      } // check for  buff size
}

void ParseTS::first_parse(int limit) {

    for (int i=limit-1; i>0; i--) {
      this.calc_resistance(i); 
      this.calc_support(i); 
    } // for loop

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
    static int BarsOnChart = 0; // Initialized once.

    if (BarsOnChart == 0) {
      pts.first_parse(Bars);
      pts.Mark_resistance();
      pts.Mark_support();
    } else if (BarsOnChart != 0 && Bars != BarsOnChart) {
      pts.calc_resistance(0); 
    }
    

    BarsOnChart = Bars;

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
