import subprocess
import pty
import os
import select
import time

class JALVInstance:
    def __init__(self, lv2_name, jack_name):
        """Start jalv with a plugin and begin to interact with it

        Parameters
        ----------
        lv2_name: str
          Name of the LV2 plugin to load
        jack_name: str
          Name of the application as it will appear in jack
        """

        self.__lv2_name = lv2_name
        self.__jack_name = jack_name

        # we run jalv with a pty so that it runs in interactive mode,
        # where a "> " prompt is displayed
        self.__out_master, out_slave = pty.openpty()
        self.__in_master, in_slave = pty.openpty()        
        self.__process = subprocess.Popen(["jalv", "-n", jack_name, "-b", "1", lv2_name], stdout=out_slave, stdin=in_slave)

        self.read_until_prompt()

    def read_controls(self):
        controls = {}
        os.write(self.__in_master, b"controls\r")
        raw_controls = self.read_until_prompt()[:-2]
        if raw_controls is None:
            return {}
        for x in raw_controls.decode("utf8").split("\r\n")[:-1]:
            k,v = x.split(" = ")
            controls[k] = float(v)
        return controls

    def read_presets(self):
        presets = []
        os.write(self.__in_master, b"presets\r")
        raw_presets = self.read_until_prompt()[:-2]
        if raw_presets is None:
            return []
        for x in raw_presets.decode("utf8").split("\r\n")[:-1]:
            s = x.split(" (")
            preset_uri = s[0]
            preset_name = ''.join(s[1:])[:-1]
            presets.append((preset_name, preset_uri))
        return presets

    def set_control(self, k, v):
        print("#set_control {} = {}".format(k,v))
        os.write(self.__in_master, bytes("{} = {}\n".format(k, v), "utf8"))
        self.read_until_prompt()

    def read_until_prompt(self):
        return self.read_until_dead_or(b"> ")

    def read_until_dead_or(self, str_pattern):
        """Consumes the process stdout until a string pattern is met or the subprocess dies

        Parameters:
        -----------
        str_pattern: str
          The string pattern to look for

        Returns:
        --------
          The read stream, as bytes
          None if the subprocess died
        """

        read_bytes=b""
        while True:
            r = self.__process.poll()
            if r is not None:
                return None
            rlist, _, _ = select.select([self.__out_master], [], [])
            if rlist:
                r = os.read(rlist[0], 1024)
                read_bytes += r
                if read_bytes.endswith(str_pattern):
                    return read_bytes
        

if __name__ == "__main__":
    
    j = JALVInstance("http://tytel.org/helm", "Helm1")
    #controls = j.read_controls()
    #print(controls)
    print(j.read_presets())
    j.set_control("osc_1_waveform", 0.5)
    print(j.read_presets())
    
