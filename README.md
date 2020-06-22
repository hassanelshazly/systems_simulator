
  

# Systems Simulator

A simple MATLAB Application that can simulate an LTI system of any order provided the input/output equation or the transfer function parameters and the input function, you can visualize the system response as well as the system states and the state space representation matrices.

  

The Application does not use any ready-made libraries or functions to implement your simulation.

It uses `Runge–Kutta Method` to solve the differential equations and `Finite Difference Methods` as an approximation to calculate the derivatives.

  

## Assumptions

- Zero initial conditions.
- The simulation time equals 30s.

  

## Getting Started

```
1. git clone https://github.com/hassanelshazly/systems_simulator
2. open MATALB and change the current folder to the repo folder
3. Run command 'systems'
```


  

## Usage
### The Input Fields

![The Input Fields](/README_imgs/Usage.png)

  
The input parameters are the based on the following equation
![The input parameters are the based on the following equation](/README_imgs/equation.png)

  

#### The input function could be
- Unit step
- Unit impulse
- Any u(t) function (must be a MATLAB expression)

  

You can also input random parameters using Random button.

  

The bottom section is used to visualize the input, output, and the states. It is adaptive depending on the number of the states of the system.

  

## Examples

### For the following forth order system
![ Fourth Order System](/README_imgs/equation2.png)


### The System Response

![Input & Output](/README_imgs/all.png)

  
### State Variables
![State Variables X<sub>1</sub> & X<sub>2</sub>](/README_imgs/all2.png)

  

![State Variables X<sub>3</sub> & X<sub>4</sub>](/README_imgs/all3.png)

  
  

## License

This project is licensed under the MIT license