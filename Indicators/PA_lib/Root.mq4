class Root : public SR_Base {

  public:
    string      TS_chart_name[];
    CombineTS*  TS_charts[];
    void Init(void);
    void Iterate_charts(TS_Element* buf);

};


void Root::Init() {
  int size = this.check_array_size(this.TS_chart_name);

  for (int j = 0; j < size; j++) {

      CombineTS* cts = new CombineTS;

      if (this.TS_chart_name[j] == "30m") cts.Setup(1, "30m", 30, Blue);
      if (this.TS_chart_name[j] == "1hr") cts.Setup(2, "1hr", 60, Magenta);
      if (this.TS_chart_name[j] == "4hr") cts.Setup(8, "4hr", 240, Blue);
      if (this.TS_chart_name[j] == "day") cts.Setup(48, "day", 1440, Orange);

      this.push_array(cts, this.TS_charts);

  }
}

void Root::Iterate_charts(TS_Element* buf) {
  int size = this.check_array_size(this.TS_charts);

  for (int j = 0; j < size; j++) {
    this.TS_charts[j].start_combine(buf);
  }
}
