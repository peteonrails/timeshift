
/*
 * Zvol.vala
 *
 * Copyright 2025 Peter Jackson <pete@peteonrails.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 *
 */

/* Functions and classes for handling ZFS datasets */

using TeeJee.Logging;
using TeeJee.ProcessHelper;
using TeeJee.GtkHelper;

public class Zvol : GLib.Object {

	/* Class for storing ZFS Volume information */

	public static double KB = 1000;
	public static double MB = 1000 * KB;
	public static double GB = 1000 * MB;

    public string name;
    public string used;
    public string available;
    public string refer;
    public string mountpoint;
    public bool mounted;
    public string encryption;
    public string type;
    public string creation;
    public string dist_info;

    public Zvol() {
    }

    public string tooltip_text() {
        return "Zvol.tooltip_text()";
    }

	public static Gee.ArrayList<Zvol> filesystems(string zpool="") {
        var list = new Gee.ArrayList<Zvol>();

        string std_out;
        string std_err;
        string cmd;
        int ret_val;
        cmd = "zfs list -t filesystem -r -H -o name,used,avail,refer,mountpoint,mounted,encryption,type,creation";
        ret_val = exec_sync(cmd, out std_out, out std_err);

        log_debug(std_out);

		foreach(string line in std_out.split("\n")){
			if (line.strip().length == 0) { continue; }
            Zvol dataset = new Zvol();
            try {
                string[] zvol_data = line.split("\t");
                dataset.name        = zvol_data[0];
                dataset.used        = zvol_data[1];
                dataset.available   = zvol_data[2];
                dataset.refer       = zvol_data[3];
                dataset.mountpoint  = zvol_data[4];
                dataset.mounted     = (zvol_data[5] == "yes");
                dataset.encryption  = zvol_data[6];
                dataset.type        = zvol_data[7];
                dataset.creation    = zvol_data[8];
            } catch (Error e) {
                throw(e);
            }
            list.add(dataset);
        }
        return(list);
	}
}
