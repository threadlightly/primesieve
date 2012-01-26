//
// Copyright (c) 2012 Kim Walisch, <kim.walisch@gmail.com>.
// All rights reserved.
//
// This file is part of primesieve.
// Homepage: http://primesieve.googlecode.com
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
//
//   * Redistributions of source code must retain the above copyright
//     notice, this list of conditions and the following disclaimer.
//   * Redistributions in binary form must reproduce the above
//     copyright notice, this list of conditions and the following
//     disclaimer in the documentation and/or other materials provided
//     with the distribution.
//   * Neither the name of the author nor the names of its
//     contributors may be used to endorse or promote products derived
//     from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
// OF THE POSSIBILITY OF SUCH DAMAGE.

#include "PrimeNumberGenerator.h"
#include "PrimeNumberFinder.h"
#include "SieveOfEratosthenes.h"
#include "config.h"
#include "bithacks.h"

#include <stdint.h>
#include <cassert>

using namespace soe;

PrimeNumberGenerator::PrimeNumberGenerator(PrimeNumberFinder& finder) :
  SieveOfEratosthenes(
      finder.getPreSieveLimit() + 1,
      finder.getSquareRoot(),
      nextHighestPowerOf2(config::SIEVESIZE_PRIMENUMBERGENERATOR),
      config::PRESIEVE_LIMIT_PRIMENUMBERGENERATOR),
  primeNumberFinder_(finder)
{
  static_assert(config::SIEVESIZE_PRIMENUMBERGENERATOR <= 4096, "Maximum sieveSize = 4096 kilobytes");
  assert(getStopNumber() <= UINT32_MAX);
}

/**
 * Generate the primes within the current segment and use them
 * to sieve with primeNumberFinder_.
 * @see SieveOfEratosthenes::sieve(uint32_t)
 */
void PrimeNumberGenerator::generate(const uint8_t* sieve, uint32_t sieveSize) {
  // GENERATE_PRIMES() is defined in SieveOfEratosthenes.h
  GENERATE_PRIMES(primeNumberFinder_.sieve, uint32_t);
}

void PrimeNumberGenerator::analyseSieve(const uint8_t* sieve, uint32_t sieveSize) {
  generate(sieve, sieveSize);
}
