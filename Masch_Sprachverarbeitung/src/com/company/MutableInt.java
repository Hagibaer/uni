package com.company;

public class MutableInt implements Comparable<MutableInt>
{
    int value = 1;
    public void increment(){++value;}
    public int getValue(){return value;}

    @Override
    public int compareTo(MutableInt o) {
        if(value < o.getValue()){
            return -1;
        }else if(value == o.getValue()){
            return 0;
        }else
            return 1;
    }
}
