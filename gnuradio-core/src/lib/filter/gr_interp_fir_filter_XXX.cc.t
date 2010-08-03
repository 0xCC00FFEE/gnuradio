/* -*- c++ -*- */
/*
 * Copyright 2004,2010 Free Software Foundation, Inc.
 * 
 * This file is part of GNU Radio
 * 
 * GNU Radio is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3, or (at your option)
 * any later version.
 * 
 * GNU Radio is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with GNU Radio; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street,
 * Boston, MA 02110-1301, USA.
 */

/*
 * WARNING: This file is automatically generated by generate_gr_fir_filter_XXX.py
 * Any changes made to this file will be overwritten.
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <@NAME@.h>
#include <@FIR_TYPE@.h>
#include <gr_fir_util.h>
#include <gr_io_signature.h>
#include <stdexcept>
#include <iostream>

@SPTR_NAME@ gr_make_@BASE_NAME@ (unsigned interpolation, const std::vector<@TAP_TYPE@> &taps)
{
  return gnuradio::get_initial_sptr (new @NAME@ (interpolation, taps));
}


@NAME@::@NAME@ (unsigned interpolation, const std::vector<@TAP_TYPE@> &taps)
  : gr_sync_interpolator ("@BASE_NAME@",
			  gr_make_io_signature (1, 1, sizeof (@I_TYPE@)),
			  gr_make_io_signature (1, 1, sizeof (@O_TYPE@)),
			  interpolation),
    d_updated (false), d_firs (interpolation)
{
  if (interpolation == 0)
    throw std::out_of_range ("interpolation must be > 0");

  std::vector<@TAP_TYPE@>	dummy_taps;
  
  for (unsigned i = 0; i < interpolation; i++)
    d_firs[i] = gr_fir_util::create_@FIR_TYPE@ (dummy_taps);

  set_taps (taps);
  install_taps(d_new_taps);
}

@NAME@::~@NAME@ ()
{
  int interp = interpolation ();
  for (int i = 0; i < interp; i++)
    delete d_firs[i];
}

void
@NAME@::set_taps (const std::vector<@TAP_TYPE@> &taps)
{
  d_new_taps = taps;
  d_updated = true;

  // round up length to a multiple of the interpolation factor
  int n = taps.size () % interpolation ();
  if (n > 0){
    n = interpolation () - n;
    while (n-- > 0)
      d_new_taps.insert(d_new_taps.begin(), 0);
  }

  assert (d_new_taps.size () % interpolation () == 0);
}


void
@NAME@::install_taps (const std::vector<@TAP_TYPE@> &taps)
{
  int nfilters = interpolation ();
  int nt = taps.size () / nfilters;

  assert (nt * nfilters == (int) taps.size ());

  std::vector< std::vector <@TAP_TYPE@> > xtaps (nfilters);

  for (int n = 0; n < nfilters; n++)
    xtaps[n].resize (nt);  

  for (int i = 0; i < (int) taps.size(); i++)
    xtaps[i % nfilters][i / nfilters] = taps[i];

  for (int n = 0; n < nfilters; n++)
    d_firs[n]->set_taps (xtaps[n]);
  
  set_history (nt);
  d_updated = false;

#if 0
  for (int i = 0; i < nfilters; i++){
    std::cout << "filter[" << i << "] = ";
    for (int j = 0; j < nt; j++)
      std::cout << xtaps[i][j] << " ";

    std::cout << "\n";
  }
#endif

}

int
@NAME@::work (int noutput_items,
		   gr_vector_const_void_star &input_items,
		   gr_vector_void_star &output_items)
{
  const @I_TYPE@ *in = (const @I_TYPE@ *) input_items[0];
  @O_TYPE@ *out = (@O_TYPE@ *) output_items[0];

  if (d_updated) {
    install_taps (d_new_taps);
    return 0;		     // history requirements may have changed.
  }

  int nfilters = interpolation ();
  int ni = noutput_items / interpolation ();
  
  for (int i = 0; i < ni; i++){
    for (int nf = 0; nf < nfilters; nf++)
      out[nf] = d_firs[nf]->filter (&in[i]);
    out += nfilters;
  }

  return noutput_items;
}
