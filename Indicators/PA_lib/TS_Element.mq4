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
    string name;
    void   set_fields(double h, double l, double o, double c, datetime dt);
};

void TS_Element::set_fields(double h, double l, double o, double c, datetime dt) {
    this.Open  = o;
    this.Close = c;
    this.High  = h;
    this.Low   = l;
    this.t     = dt;
}
