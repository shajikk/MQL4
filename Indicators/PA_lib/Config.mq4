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
