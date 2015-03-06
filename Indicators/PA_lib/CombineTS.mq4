class CombineTS : public SR_Base {

  public:
    int     buf_depth;
    void    start_combine(TS_Element* buf);
    void    bufdepth0(TS_Element* buf);
    void    bufdepthN(TS_Element* buf);

    TS_Element* TS_sparse[];
    ParseTS*    pts;

    CombineTS() { 
      this.pts = new ParseTS;;
    };
    
};

void CombineTS::start_combine(TS_Element* buf) {
  if (this.buf_depth == 1) this.bufdepth0(buf);
  if (this.buf_depth != 1) this.bufdepthN(buf);
}


void CombineTS::bufdepth0(TS_Element* buf) {
  TS_Element* local_buf;

  local_buf = new TS_Element();
  local_buf.set_fields(buf.High, buf.Low, buf.Open, buf.Close, buf.t);
  pts.process_candle_resistance(local_buf);

  local_buf = new TS_Element();
  local_buf.set_fields(buf.High, buf.Low, buf.Open, buf.Close, buf.t);
  pts.process_candle_support(local_buf);

}

void CombineTS::bufdepthN(TS_Element* buf) {

  TS_Element* local_buf;
  local_buf = new TS_Element();

  local_buf.set_fields(buf.High, buf.Low, buf.Open, buf.Close, buf.t);

  this.push_array(local_buf, this.TS_sparse);

  if (this.check_array_size(this.TS_sparse) != buf_depth) return;

  int size=ArraySize(this.TS_sparse);

  double val_open  = 0.0;
  double val_close = 0.0;
  double val_high  = 0.0;
  double val_low   = 0.0;
  datetime val_time  = 0;

  for (int j=size; j< size; j++) {
    if (j == 0) { 
      val_open = this.TS_sparse[j].Open;
      val_high = this.TS_sparse[j].High;
      val_low  = this.TS_sparse[j].Low;
    }

    if (this.TS_sparse[j].High > val_high) {
      val_high = this.TS_sparse[j].High;
    }

    if (this.TS_sparse[j].Low < val_low) {
      val_low = this.TS_sparse[j].Low;
    }

    if (j == size-1) { 
      val_close = this.TS_sparse[j].Close;
      val_time = this.TS_sparse[j].t;
    }
  } 

  for (int j=size; j< size; j++) {
    delete this.TS_sparse[j];
  }


  TS_Element* buf1;

  buf1 = new TS_Element();
  buf1.set_fields(val_high, val_low, val_open, val_close, val_time);
  pts.process_candle_resistance(buf1);

  buf1 = new TS_Element();
  buf1.set_fields(val_high, val_low, val_open, val_close, val_time);
  pts.process_candle_support(buf1);

}

