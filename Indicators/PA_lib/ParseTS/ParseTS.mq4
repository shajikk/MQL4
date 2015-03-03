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

    uint name_counter;

    bool    r_already_added;
    bool    s_already_added;
    void    process_candle(int i);
    void    calc_resistance(int i);
    void    calc_support(int i);
    void    Limit_resistance(void);
    void    Limit_support(void);
    void    compare_resistance(void);
    void    compare_support(void);
    void    push_resistance();
    void    push_support();
    
    ParseTS() { 
      this.r_already_added = false; 
      this.s_already_added = false; 
      this.name_counter = 0;
    };

};


void ParseTS::process_candle(int i) {
      this.calc_resistance(i); 
      this.Limit_resistance();
      this.calc_support(i); 
      this.Limit_support();
}
