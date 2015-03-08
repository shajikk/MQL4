//+------------------------------------------------------------------+
//| Config class
//+------------------------------------------------------------------+

class SR_config : public SR_Base {

  public:
    double  pips;
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

}

SR_config cfg;
