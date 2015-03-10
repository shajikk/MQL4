class CombineTS : public SR_Base {

  public:
    int     chart_period;
    bool    base_chart; 
    void    start_combine(TS_Element* buf);
    void    start_Process(void);
    void    Setup(string tag, int mins, color clr);

    int     SR_band;
    int     window;
    int     max_samples;

    TS_Element* TS_sparse[];
    ParseTS*    pts;

};

void CombineTS::Setup(string tag, int mins, color clr) {

  this.pts = new ParseTS;;
  this.pts.BarsOnChart = 0; 
  this.base_chart = false;

  this.pts.band_value  = this.SR_band * cfg.pips;
  this.pts.window      = this.window;
  this.pts.max_samples = this.max_samples;

  this.pts.Clr   = clr; 
  this.pts.tag   = tag; 
  this.chart_period = mins;

  if (this.chart_period == base_chart_period) {
    this.base_chart = true;
  }

  this.chart_id = ChartID(); 

  if (spawn_child_chart && !this.base_chart) {
    this.chart_id = ChartOpen(NULL, mins);
    this.pts.chart_id = this.chart_id;
  } 
}

void CombineTS::start_combine(TS_Element* buf) {
  TS_Element* local_buf;

  local_buf = new TS_Element();
  local_buf.set_fields(buf.High, buf.Low, buf.Open, buf.Close, buf.t);
  pts.process_candle_resistance(local_buf);

  local_buf = new TS_Element();
  local_buf.set_fields(buf.High, buf.Low, buf.Open, buf.Close, buf.t);
  pts.process_candle_support(local_buf);

}



void CombineTS::start_Process() {
    if (this.pts.BarsOnChart == 0) {

      for (int i=iBars(NULL, this.chart_period) -1; i>1; i--) {

        TS_Element* buf;
        buf = new TS_Element();
        buf.set_fields(iHigh(NULL, this.chart_period, i), 
                       iLow(NULL, this.chart_period, i), 
                       iOpen(NULL, this.chart_period, i), 
                       iClose(NULL, this.chart_period, i), 
                       iTime(NULL, this.chart_period, i));

        this.start_combine(buf);
        delete(buf);

      }

    } else if (this.pts.BarsOnChart != 0 && iBars(NULL, this.chart_period) != this.pts.BarsOnChart) {


        TS_Element* buf;
        buf = new TS_Element();
        buf.set_fields(iHigh(NULL, this.chart_period, 1), 
                       iLow(NULL, this.chart_period, 1), 
                       iOpen(NULL, this.chart_period, 1), 
                       iClose(NULL, this.chart_period, 1), 
                       iTime(NULL, this.chart_period, 1));

        this.start_combine(buf);
        delete(buf);

    }
    

    this.pts.BarsOnChart = iBars(NULL, this.chart_period);
}

