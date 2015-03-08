//+------------------------------------------------------------------+
//| Base class for all other derive classes.
//+------------------------------------------------------------------+


class SR_Base {

  public:
    long    chart_id;

    template<typename T>
    void    push_array(T element, T &arr[]);

    template<typename T>
    T pop_array(T &arr[]);

    template<typename T>
    T pop0_array(T &arr[]);

    template<typename T>
    int check_array_size(T &arr[]);
 
    template<typename T>
    void deleteN0_array(T &arr[], int n, bool free);

    template<typename T>
    void deleteN0_array_fix_chart(T &arr[], int n, bool free);

    template<typename T>
    void debug_array(T &arr[]);

    template<typename T>
    void overwrite_last_element(T element, T &arr[]);

    template<typename T>
    T SR_Base::get_last_element(T &arr[]);

};

template<typename T>
void SR_Base::push_array(T element, T &arr[]) {
  int size=ArraySize(arr);
  ArrayResize(arr, size+1);
  arr[size] = element;
}

template<typename T>
T SR_Base::pop_array(T &arr[]) {

  int size=ArraySize(arr);

  if (size != 0) {
    T element = arr[size-1];
    ArrayResize(arr, size-1);
    return  element;
  }
  return NULL;
  
}

template<typename T>
T SR_Base::pop0_array(T &arr[]) {

  int size=ArraySize(arr);

  if (size != 0) {
    ArraySetAsSeries(arr, true);
    T element = arr[size-1];
    ArrayResize(arr, size-1);
    ArraySetAsSeries(arr, false);
    return  element;
  }
  return NULL;
  
}


template<typename T>
  void SR_Base::deleteN0_array(T &arr[], int n, bool free) {

  int size=ArraySize(arr);

  if (size != 0 && n <= size) {
    ArraySetAsSeries(arr, true);

    /*
    0 1 2 3 4 5 6 (7)  s    (s = 7)
    0 1 2 3       (-3) s-n  (n=3) 
            4 5 6 
    */
 
    if (free) {
      for (int j=size-n; j< size; j++) {
         delete arr[j];
      } 
    }

    ArrayResize(arr, size-n);
    ArraySetAsSeries(arr, false);
  }
  
}

template<typename T>
  void SR_Base::deleteN0_array_fix_chart(T &arr[], int n, bool free) {

  int size=ArraySize(arr);

  if (size != 0 && n <= size) {
    ArraySetAsSeries(arr, true);

    /*
    0 1 2 3 4 5 6 (7)  s    (s = 7)
    0 1 2 3       (-3) s-n  (n=3) 
            4 5 6 
    */
 
    if (free) {
      for (int j=size-n; j< size; j++) {
        if (ObjectFind(this.chart_id, arr[j].name) != -1) {
          ObjectDelete(this.chart_id, arr[j].name); 
        } 
        delete arr[j];
      } 
    }

    ArrayResize(arr, size-n);
    ArraySetAsSeries(arr, false);
  }
  
}


template<typename T>
  int SR_Base::check_array_size(T &arr[]) {
  return ArraySize(arr);
}


template<typename T>
  void SR_Base::overwrite_last_element(T element, T &arr[]) {
  int size =  ArraySize(arr);
  if (size > 0) {
    delete arr[size-1];
    arr[size-1] = element;
  }
}


template<typename T>
  T SR_Base::get_last_element(T &arr[]) {
  int size =  ArraySize(arr);
  if (size > 0) {
    return arr[size-1];
  }
  return NULL;
}


// ------ Function for testing ------
template<typename T>
void SR_Base::debug_array(T &arr[]) {

  int size=ArraySize(arr);
  for (i = 0; i < size; i++) {
    Print("DEBUG idx = " + i + " Value = " + arr[i] + "\n"); 
  }

}
