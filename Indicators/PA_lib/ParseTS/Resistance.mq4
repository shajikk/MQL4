void ParseTS::Limit_resistance() {
  int size=ArraySize(this.TS_r_sparse);
  if (size > max_samples) {
    int to_remove = size - max_samples;
    this.deleteN0_array_fix_chart(this.TS_r_sparse, to_remove, true);
  }
}

void ParseTS::compare_resistance(void) {

   double delta = MathAbs(this.r_current.value - this.r_previous.value);

   if (delta < cfg.band_value) {
     if (this.r_current.value > this.r_previous.value) {

       if (!this.r_previous.valid) delete this.r_previous;
       this.r_previous = this.r_current;

       return;
     }
     delete (this.r_current);
   }

   if (delta > cfg.band_value) {

     if (this.r_current.value > this.r_previous.value) {

       if (!this.r_previous.valid) delete this.r_previous;
       this.r_previous = this.r_current;

       this.r_already_added = false;
       return;
     }

     if (this.r_current.value < this.r_previous.value) {

       if (!this.r_already_added) {
         this.push_resistance();
       }

       this.r_already_added = true;

       if (!this.r_previous.valid) delete this.r_previous;
       this.r_previous = this.r_current;

       return;
     }
   } 
}

void ParseTS::push_resistance() {
  this.r_previous.valid = true;
  this.r_previous.name = "r_" + this.name_counter;
  this.push_array(this.r_previous, this.TS_r_sparse); 
  this.name_counter++;

  ObjectCreate(this.r_previous.name, OBJ_ARROW_DOWN,0,
               this.r_previous.t, this.r_previous.value);
  ObjectSet(this.r_previous.name, OBJPROP_COLOR, Clr);
  cfg.push_array(this.r_previous.name, cfg.chartObj);
}

void ParseTS::calc_resistance(TS_Element* buf) {
      
      this.push_array(buf, this.r_buffer); 

      int size = this.check_array_size(this.r_buffer);

      if (size == window) {

        double highest = 0.0;
        int sample = 0;


        for (int j = 0; j < size; j++) {

          if (this.r_buffer[j].Close > this.r_buffer[j].Open) {
            this.r_buffer[j].value = this.r_buffer[j].Close;
          } else {
            this.r_buffer[j].value = this.r_buffer[j].Open;
          } 

          // Initialize
          if (j == 0) { 
            highest = this.r_buffer[j].value;
            sample  = 0;
          }

          if (this.r_buffer[j].value > highest) {
            highest = this.r_buffer[j].value;
            sample = j;
          }

        }

         
        for (int j = 0; j < size; j++) {
          if (j != sample) {
            delete this.r_buffer[j];
          }  
        } 

        this.r_current = this.r_buffer[sample];
        ArrayResize(r_buffer, 0); // Clear array memory


        if (this.r_previous != NULL) {
          this.compare_resistance();
        } else {
          // r_current becomes r_previous
          this.r_previous = this.r_current;
        }

      } // check for  buff size
}

