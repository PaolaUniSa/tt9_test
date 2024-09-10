<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project implements 10 programmable digital LIF neurons with programmable delays and 208 synapsis. The neurons are arranged in 2 layers (24 inputs + FC (8 neurons) + FC (2 neurons) ). Spikes_in directly maps to the inputs of the first layer neurons. When an input spike is received, it is first multiplied by an 8 bit weight, programmable from an SPI interface, 1 per input neuron. This 8 bit value is then added to the membrane potential of the respective neuron. When the first layer neurons activate, its pulse is routed to each of the 3 neurons in the next layer. There are 208 (24x8+8x2) programmable weights describing the connectivity between the input spikes and the first layer (192 weights=24x8), the first and second layers (16 weights=8x2). Output spikes from the 2nd layer drive spikes_out.

## How to test

After reset, program the neuron threshold, leak rate, and refractory period. Additionally program the first and second layer weights and delays. Once programmed activate spikes_in to represent input data, track spikes_out synchronously.

## External hardware

List external hardware used in your project (e.g. PMOD, LED display, etc), if any
