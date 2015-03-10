class Root : public SR_Base {

  public:
    string      TS_chart_name[];
    CombineTS*  TS_charts[];
    void Init(void);
    void Deinit(void);
    void Iterate_charts();

};


void Root::Init() {
  int size = this.check_array_size(this.TS_chart_name);

  for (int j = 0; j < size; j++) {

      CombineTS* cts = new CombineTS;

      if (this.TS_chart_name[j] == "30m") { 
        cts.SR_band     = 5;
        cts.window      = 3;
        cts.max_samples = 3;
        cts.Setup("30m", PERIOD_M30, Blue); 
      };

      if (this.TS_chart_name[j] == "1hr") {
        cts.SR_band     = 10;
        cts.window      = 4;
        cts.max_samples = 5;
        cts.Setup("1hr", PERIOD_H1, Magenta);
      }

      if (this.TS_chart_name[j] == "4hr") {
        cts.SR_band     = 20;
        cts.window      = 4;
        cts.max_samples = 5;
        cts.Setup("4hr", PERIOD_H4, Blue);
      }

      if (this.TS_chart_name[j] == "day") {
        cts.SR_band     = 60;
        cts.window      = 2;
        cts.max_samples = 5;
        cts.Setup("day", PERIOD_D1, Orange);
      } 

      this.push_array(cts, this.TS_charts);

  }
}

void Root::Iterate_charts() {
  int size = this.check_array_size(this.TS_charts);

  for (int j = 0; j < size; j++) {
    this.TS_charts[j].start_Process();
  }
}


void Root::Deinit() {
  int size = this.check_array_size(this.TS_charts);

  for (int j = 0; j < size; j++) {
    if (spawn_child_chart && !this.TS_charts[j].base_chart) {
      ChartClose(this.TS_charts[j].chart_id);
    }
  }
}
