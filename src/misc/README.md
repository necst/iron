# Board Definition Files
This files are not the IRON team property but are properties of Avnet and TUL.
You can find pynq-z2 BDF [here](http://www.tul.com.tw/ProductsPYNQ-Z2.html) and Avnet BDF at its GitHub repository [here](https://github.com/Avnet/bdf)

Once locally available copy the bdf folder into the target Vivado version, e.g., `sudo cp -R pynq-z2/ /xilinx/software/Vivado/2019.2/data/boards/board_files/`.



Troubleshoot for possible permission issues:
once copied change also the permissions
`sudo chmod +xr pynqz2`
