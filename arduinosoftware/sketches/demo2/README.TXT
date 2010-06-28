This demo is using 16-bit samples and updates once per second.
Channels 0-3 assume K-type thermocouples and report temps in F.
The values are returned in floating-point format.
Both the mcp900 and mcp3424 are running in continous sampling mode.
Note: A workaround is in place to attempt increase reliable readings:
  1) the ambient sensor's pointer register is left pointing to the temperature
  2) the mcp3424 is reset to defaults at the start of each sampling cycle.

