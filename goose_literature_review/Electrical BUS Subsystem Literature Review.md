# Electrical BUS Subsystem Literature Review

The goal of this document is to provide an overview of the existing CubeSat designs as it pertains to the electrical subsystem specifically, distill main themes of the designs, and determine edge-case examples to guide the constraint definition in the further phases.

# Overview of the Electrical BUS Subsystem

The Electrical BUS subsystem’s goal is to provide the CubeSat with a centralized point of control, which at high level will involve observing “indicators” and driving “actuators”. More specifically, Electrical BUS will interact with the PAYload, RF, and EPS subsystems to manage the state of affairs on the CubeSat. Operations of the electrical subsystem may include “directing the PAYload subsystem to send data to the RF subsystem to downlinking”, “acquiring uplink data from RF to perform a reboot”.

# Literature review methodology

As it pertains to the design, the main components that make up the electrical subsystem essentially boil down to three categories: control unit (i.e. device(s) responsible for carrying out generic operations of the electrical subsystem, e.g. an MCU), protocol (i.e. an interface for connecting two or more devices and allowing them to share data in one way or another, e.g. I2C), and peripherals (i.e. device(s) responsible for a particular function within the Electrical BUS subsystem, e.g. a watchdog). This classification is not a recognized one, but has been found to be useful when conducting this literature review since the overwhelming majority of the designs can be deconstructed into components each of which would fit into one of these categories \[subjective\].

# Design Space

*Description: Your goal is to determine an estimate for feasible design specifications for your subsystem based on the literature of other \~3U cubesat designs.* 

*What to include:* 

- [ ] *Minimum, average, and maximum specifications for your subsystem from other 3U cubesats (e.g. 3U cubesat mass ranges from X → Y kg)*  
- [ ] *Determination of what we can feasibly produce in house (e.g. types of ADCS systems)*

This section outlines the resulting design space for the Electrical BUS Subsystem based on the literature review of the components outlined in the Appendices A through D.

// TODO

# COTS (Commercial Off the Shelf) Design Alternatives

*Description: Determine what COTS solutions exist if we can’t produce a certain part of the subsystem in house. Find a COTS option for each in house design.*

- *Will inform trades later on for COTS vs in house risks*

This section outlines alternative off-the-shelf components that would in part or in full fulfil the operating requirements of the subsystem. 

// TODO

# System Architecture and Budgets

*Description: Determine recommended system architectures and budgets (mass, volume, power, link, etc. budget) from existing cubesats and standards.*

# Appendix A: Master list of OBCs

# Appendix A: Control Unit literature review

// TODO

# Appendix B: Protocol literature review

// TODO

# Appendix C: Peripheral literature review

// TODO

# Appendix D: Uncategorized examples

// TODO  
