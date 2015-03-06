
void ParseTS::Limit_support() {
  int size=ArraySize(this.TS_s_sparse);
  if (size > max_samples) {
    int to_remove = size - max_samples;
    this.deleteN0_array_fix_chart(this.TS_s_sparse, to_remove, true);
  }
}

void ParseTS::compare_support(void) {

   double delta = MathAbs(this.s_current.value - this.s_previous.value);

   if (delta < cfg.band_value) {
     if (this.s_current.value < this.s_previous.value) {

       if (!this.s_previous.valid) delete this.s_previous;
       this.s_previous = this.s_current;

       return;
     }
     delete (this.s_current);
   }

   if (delta > cfg.band_value) {

     if (this.s_current.value < this.s_previous.value) {

       if (!this.s_previous.valid) delete this.s_previous;
       this.s_previous = this.s_current;

       this.s_already_added = false;
       return;
     }

     if (this.s_current.value > this.s_previous.value) {
       if (!this.s_already_added) {
         this.push_support();
       }
       this.s_already_added = true;

       if (!this.s_previous.valid) delete this.s_previous;
       this.s_previous = this.s_current;

       return;
     }
   } 
}

void ParseTS::push_support() {
  this.s_previous.valid = true;
  this.s_previous.name = "s_" + this.name_counter;
  this.push_array(this.s_previous, this.TS_s_sparse); 
  this.name_counter++;

  ObjectCreate(this.s_previous.name, OBJ_ARROW_UP,0,
               this.s_previous.t, this.s_previous.value);
  ObjectSet(this.s_previous.name, OBJPROP_COLOR, Clr);
  cfg.push_array(this.s_previous.name, cfg.chartObj);
}

void ParseTS::calc_support(TS_Element* buf) {

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
