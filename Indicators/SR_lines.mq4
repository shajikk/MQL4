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
    TS_Element* current;
    TS_Element* previous;
    TS_Element* TS_sparse[];
    TS_Element* buffer[];
    bool    already_added;
    void    first_parse(int limit);
    void    calc_resistance(int i);
    void    Mark_resistance(void);
    void    push_sparse(TS_Element* element);
    void    compare_resistance(void);
    
    ParseTS() { this.already_added = false; };

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
    //Print("loc = r_" + i + "\n");
    //Print("t = " +  TimeToStr(element.t, TIME_DATE|TIME_MINUTES) + "\n");
    //Print("val = " + element.value + "\n");
    ObjectCreate("r_"+i, OBJ_ARROW_DOWN,0,element.t, element.value);
    ObjectSet("r_"+i, OBJPROP_COLOR, Clr);
    cfg.push_array("r_"+i, cfg.chartObj);
  }

}

void ParseTS::compare_resistance(void) {

   double delta = MathAbs(this.current.value - this.previous.value);

   if (delta < cfg.band_value) {
     if (this.current.value > this.previous.value) {
       this.previous = this.current;
       return;
     }
   }

   //if (this.current.lower_limit > this.previous.upper_limit) {
   if (delta > cfg.band_value) {

     if (this.current.value > this.previous.value) {
       this.previous = this.current;
       this.already_added = false;
       return;
     }

     if (this.current.value < this.previous.value) {
       if (!this.already_added) {
         this.push_array(this.previous, this.TS_sparse); 
       }
       this.already_added = true;
       this.previous = this.current;
       return;
     }
   } 
}


void ParseTS::calc_resistance(int i) {

      TS_Element* buf;
      buf = new TS_Element();
      buf.set_fields(High[i], Low[i], Open[i], Close[i], Time[i]);
      this.push_array(buf, this.buffer); 

      int size = this.check_array_size(this.buffer);

      if (size == window) {

        double highest = 0.0;
        int sample = 0;


        for (int j = 0; j < size; j++) {

          if (this.buffer[j].Close > this.buffer[j].Open) {
            this.buffer[j].value = this.buffer[j].Close;
          } else {
            this.buffer[j].value = this.buffer[j].Open;
          } 

          // Initialize
          if (j == 0) { 
            highest = this.buffer[j].value;
            sample  = 0;
          }

          if (this.buffer[j].value > highest) {
            highest = this.buffer[j].value;
            sample = j;
          }

        }

         
        for (int j = 0; j < size; j++) {
          if (j != sample) {
            delete this.buffer[j];
          }  
        } 

        this.current = this.buffer[sample];
        ArrayResize(buffer, 0); // Clear array memory


        if (this.previous != NULL) {
          this.compare_resistance();
        } else {
          // current becomes previous
          this.previous = this.current;
        }

      } // check for  buff size
}

void ParseTS::first_parse(int limit) {

    for (int i=limit-1; i>0; i--) {
      this.calc_resistance(i); 
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
    } else if (BarsOnChart != 0 && Bars != BarsOnChart) {
    }
    

    BarsOnChart = Bars;

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
