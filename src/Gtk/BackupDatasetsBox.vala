/*
 * BackupDatasetsBox.vala
 *
 * Copyright 2025 Peter Jackson <pete@peteonrails.com>
 * Copyright 2012-2018 Tony George <teejeetech@gmail.com>
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

using Gtk;
using Gee;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JsonHelper;
using TeeJee.ProcessHelper;
using TeeJee.GtkHelper;
using TeeJee.System;
using TeeJee.Misc;

class BackupDatasetsBox : Gtk.Box{

	private Gtk.TreeView zfs_datasets;
	private Gtk.InfoBar infobar_location;
	private Gtk.Label lbl_infobar_location;
	private Gtk.Label lbl_common;

	private Gtk.Window parent_window;

	public BackupDatasetsBox (Gtk.Window _parent_window) {

		log_debug("BackupDatasetsBox: BackupDatasetsBox()");

		GLib.Object(orientation: Gtk.Orientation.VERTICAL, spacing: 6); // work-around
		parent_window = _parent_window;
		margin = 12;

		var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
		add(hbox);

		add_label_header(hbox, _("Select Datasets to Snapshot"), true);

		// buffer
		var label = add_label(hbox, "");
        label.hexpand = true;

		// refresh device button

		var size_group = new Gtk.SizeGroup(SizeGroupMode.HORIZONTAL);
		var btn_refresh = add_button(hbox, _("Refresh"), "", size_group, null);
        btn_refresh.clicked.connect(()=>{
			App.update_datasets();
			tv_datasets_refresh();
		});

		init_tv_devices_zfs();

		// infobar
		init_infobar_location();

		log_debug("BackupDatasetsBox: BackupDatasetsBox(): exit");
    }

    public void refresh(){

		tv_datasets_refresh();

		check_backup_location();

        lbl_common.label = "<i>• %s\n• %s\n• %s</i>".printf(
            _("ZFS Datasets displayed above have file system mountpoints."),
            _("ZFS snapshots are saved within each dataset."),
            _("Snapshots are saved to /.zfs/snapshot within the mounted dataset. Other locations are not supported.")
        );

	}

    // TODO - make this more OO
    private void init_tv_devices_zfs(){
		zfs_datasets = add_treeview(this);
		zfs_datasets.vexpand = true;
		zfs_datasets.headers_clickable = true;
		zfs_datasets.activate_on_single_click = true;

		// device name
		Gtk.CellRendererPixbuf cell_pix;
		Gtk.CellRendererToggle cell_radio;
		Gtk.CellRendererText cell_text;

		var col = add_column_icon_radio_text(zfs_datasets, _("Select"),
			out cell_pix, out cell_radio, out cell_text);

		col.resizable = true;

		col.set_cell_data_func(cell_pix, (cell_layout, cell, model, iter)=>{
			Zvol dev;
			model.get (iter, 0, out dev, -1);

            ((Gtk.CellRendererText)cell).text = dev.name;
		});

        // Dataset

        col = add_column_text(zfs_datasets, _("Dataset"), out cell_text);

        col.set_cell_data_func(cell_text, (cell_layout, cell, model, iter)=>{
            Zvol dev;
            model.get (iter, 0, out dev, -1);
            ((Gtk.CellRendererText)cell).text = dev.name;
//            ((Gtk.CellRendererText)cell).sensitive = (dev.type != "disk");
        });



        // type

        col = add_column_text(zfs_datasets, _("Type"), out cell_text);

        col.set_cell_data_func(cell_text, (cell_layout, cell, model, iter)=>{
            Zvol dev;
            model.get (iter, 0, out dev, -1);
            ((Gtk.CellRendererText)cell).text = dev.type;
//            ((Gtk.CellRendererText)cell).sensitive = (dev.type != "disk");
        });

        
        // size

        col = add_column_text(zfs_datasets, _("Used"), out cell_text);
        cell_text.xalign = (float) 1.0;

        col.set_cell_data_func(cell_text, (cell_layout, cell, model, iter)=>{
            Zvol dev;
            model.get (iter, 0, out dev, -1);

            ((Gtk.CellRendererText)cell).text = dev.used;
//            ((Gtk.CellRendererText)cell).sensitive = (dev.type != "disk");
        });

        // free

        col = add_column_text(zfs_datasets, _("Free"), out cell_text);
        cell_text.xalign = (float) 1.0;

        col.set_cell_data_func(cell_text, (cell_layout, cell, model, iter)=>{
            Zvol dev;
            model.get (iter, 0, out dev, -1);

            ((Gtk.CellRendererText)cell).text = dev.available;

//            ((Gtk.CellRendererText)cell).sensitive = (dev.type != "disk");
        });
        
        // Refer

        col = add_column_text(zfs_datasets, _("Refer"), out cell_text);
        cell_text.xalign = (float) 1.0;

        col.set_cell_data_func(cell_text, (cell_layout, cell, model, iter)=>{
            Zvol dev;
            model.get (iter, 0, out dev, -1);

            ((Gtk.CellRendererText)cell).text = dev.refer;

//            ((Gtk.CellRendererText)cell).sensitive = (dev.type != "disk");
        });


        // Encryption

        col = add_column_text(zfs_datasets, _("Encryption"), out cell_text);
        cell_text.xalign = 0.0f;

        col.set_cell_data_func(cell_text, (cell_layout, cell, model, iter)=>{
            Zvol dev;
            model.get (iter, 0, out dev, -1);

            ((Gtk.CellRendererText)cell).text = dev.encryption;
//            ((Gtk.CellRendererText)cell).sensitive = (dev.type != "disk");
        });

        // Mountpoint

        col = add_column_text(zfs_datasets, _("Mountpoint"), out cell_text);
        cell_text.xalign = 0.0f;

        col.set_cell_data_func(cell_text, (cell_layout, cell, model, iter)=>{
            Zvol dev;
            model.get (iter, 0, out dev, -1);

            ((Gtk.CellRendererText)cell).text = dev.mountpoint;

    //        ((Gtk.CellRendererText)cell).sensitive = (dev.type != "disk");
        });

        // Mounted?
        col = add_column_text(zfs_datasets, _("Mounted?"), out cell_text);
        cell_text.xalign = 0.0f;

        col.set_cell_data_func(cell_text, (cell_layout, cell, model, iter)=>{
            Zvol dev;
            model.get (iter, 0, out dev, -1);

            ((Gtk.CellRendererText)cell).text = dev.mounted ? "Yes" : "No";

    //        ((Gtk.CellRendererText)cell).sensitive = (dev.type != "disk");
        });

        // Creation
        col = add_column_text(zfs_datasets, _("Creation Date"), out cell_text);
        cell_text.xalign = 0.0f;

        col.set_cell_data_func(cell_text, (cell_layout, cell, model, iter)=>{
            Zvol dev;
            model.get (iter, 0, out dev, -1);

            ((Gtk.CellRendererText)cell).text = dev.creation;

    //        ((Gtk.CellRendererText)cell).sensitive = (dev.type != "disk");
        });


        // buffer

        col = add_column_text(zfs_datasets, "", out cell_text);
        col.expand = true;

		// events

		zfs_datasets.row_activated.connect((path, column) => {
			var store = (Gtk.TreeStore) zfs_datasets.model;
			var selection = zfs_datasets.get_selection();

			selection.selected_foreach((model, path, iter) => {
				Device dev;
				store.get (iter, 0, out dev);

				if ((App.repo.device == null) || (App.repo.device.uuid != dev.uuid)){
					try_change_device(dev);
				}
				else{
					return;
				}
			});

			store.foreach((model, path, iter) => {
				Device dev;
				store.get (iter, 0, out dev);

				if ((App.repo.device != null) && (App.repo.device.uuid == dev.uuid)){
					store.set (iter, 3, true);
					//tv_devices.get_selection().select_iter(iter);
				}
				else{
					store.set (iter, 3, false);
				}

				return false; // continue
			});
		});
	}

	private void init_infobar_location(){

		var infobar = new Gtk.InfoBar();
		infobar.no_show_all = true;
		add(infobar);
		infobar_location = infobar;

		var content = (Gtk.Box) infobar.get_content_area();
		var label = add_label(content, "");
		lbl_infobar_location = label;

		// scrolled
		var scrolled = new Gtk.ScrolledWindow(null, null);
		scrolled.set_shadow_type (ShadowType.ETCHED_IN);
		scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
		scrolled.vscrollbar_policy = Gtk.PolicyType.NEVER;
		scrolled.set_size_request(-1, 100);
		this.add(scrolled);

		label = new Gtk.Label("");
		label.set_use_markup(true);
		label.xalign = (float) 0.0;
		label.wrap = true;
		label.wrap_mode = Pango.WrapMode.WORD;
		label.margin = 6;
		scrolled.add(label);
		lbl_common = label;
	}

	private void try_change_device(Device dev){

		log_debug("try_change_device: %s".printf(dev.device));

		if (dev.type == "disk"){

			bool found_child = false;

			if ((App.btrfs_mode && (dev.fstype == "btrfs")) || (App.zfs_mode && (dev.fstype == "zfs")) || (!App.btrfs_mode && dev.has_linux_filesystem())){

				change_backup_device(dev);
				found_child = true;
			}

			if (!found_child){

				// find first valid partition

				foreach (var child in dev.children){

					if ((App.btrfs_mode && (child.fstype == "btrfs")) || (App.zfs_mode && (dev.fstype == "zfs")) || ((!App.btrfs_mode && !App.zfs_mode) && child.has_linux_filesystem())){

						change_backup_device(child);
						found_child = true;
						break;
					}
				}
			}

			if (!found_child){

				string msg = _("Selected device does not have Linux partition");

				if (App.btrfs_mode){
					msg = _("Selected device does not have BTRFS partition");
				}
				else if (App.zfs_mode){
                    msg = _("Selected device does not have ZFS partition");
                }


				lbl_infobar_location.label = "<span weight=\"bold\">%s</span>".printf(msg);
				infobar_location.message_type = Gtk.MessageType.ERROR;
				infobar_location.no_show_all = false;
				infobar_location.show_all();
			}
		}
		else if (dev.has_children()){

			// select the child instead of parent
			change_backup_device(dev.children[0]);
		}
		else if (!dev.has_children()){

			// select the device
			change_backup_device(dev);
		}
		else {

			// ask user to select
			lbl_infobar_location.label = "<span weight=\"bold\">%s</span>".printf(_("Select a partition on this disk"));
			infobar_location.message_type = Gtk.MessageType.ERROR;
			infobar_location.no_show_all = false;
			infobar_location.show_all();
		}
	}

	private void change_backup_device(Device pi){

		// return if device has not changed
		if ((App.repo.device != null) && (pi.uuid == App.repo.device.uuid)){ return; }

		gtk_set_busy(true, parent_window);

		log_debug("\n");
		log_msg("selected device: %s".printf(pi.device));
		log_debug("fstype: %s".printf(pi.fstype));

		App.repo = new SnapshotRepo.from_device(pi, parent_window, App.btrfs_mode, App.zfs_mode);

		if (pi.fstype == "luks"){

			App.update_partitions();

			var dev = Device.find_device_in_list(App.partitions, pi.uuid);

			if (dev.has_children()){

				log_debug("has children");

				if (dev.children[0].has_linux_filesystem()){

					log_debug("has linux filesystem: %s".printf(dev.children[0].fstype));
					log_msg("selecting child device: %s".printf(dev.children[0].device));

					App.repo = new SnapshotRepo.from_device(dev.children[0], parent_window, App.btrfs_mode, App.zfs_mode);
					tv_datasets_refresh();
				}
				else{
					log_debug("does not have linux filesystem");
				}
			}
		}

		check_backup_location();

		gtk_set_busy(false, parent_window);
	}

	private bool check_backup_location(){

		bool ok = true;

		App.repo.check_status();
		string message = App.repo.status_message;
		string details = App.repo.status_details;
		int status_code = App.repo.status_code;

		// TODO: call check on repo directly

		message = escape_html(message);
		details = escape_html(details);

		if (App.live_system()){

			switch (status_code){
			case SnapshotLocationStatus.NOT_SELECTED:
				lbl_infobar_location.label = "<span weight=\"bold\">%s</span>".printf(details);
				infobar_location.message_type = Gtk.MessageType.ERROR;
				infobar_location.no_show_all = false;
				infobar_location.show_all();
				ok = false;
				break;

			case SnapshotLocationStatus.NOT_AVAILABLE:
				lbl_infobar_location.label = "<span weight=\"bold\">%s</span>".printf(message);
				infobar_location.message_type = Gtk.MessageType.ERROR;
				infobar_location.no_show_all = false;
				infobar_location.show_all();
				ok = false;
				break;

			case SnapshotLocationStatus.READ_ONLY_FS:
			case SnapshotLocationStatus.HARDLINKS_NOT_SUPPORTED:
				lbl_infobar_location.label = "<span weight=\"bold\">%s</span>".printf(message);
				infobar_location.message_type = Gtk.MessageType.ERROR;
				infobar_location.no_show_all = false;
				infobar_location.show_all();
				ok = false;
				break;

			case SnapshotLocationStatus.NO_BTRFS_SYSTEM:
				lbl_infobar_location.label = "<span weight=\"bold\">%s</span>".printf(details);
				infobar_location.message_type = Gtk.MessageType.ERROR;
				infobar_location.no_show_all = false;
				infobar_location.show_all();
				ok = false;
				break;

			case SnapshotLocationStatus.NO_SNAPSHOTS_HAS_SPACE:
			case SnapshotLocationStatus.NO_SNAPSHOTS_NO_SPACE:
				lbl_infobar_location.label = "<span weight=\"bold\">%s</span>".printf(
					_("There are no snapshots on this device"));
				infobar_location.message_type = Gtk.MessageType.ERROR;
				infobar_location.no_show_all = false;
				infobar_location.show_all();
				//ok = false;
				break;

			case SnapshotLocationStatus.HAS_SNAPSHOTS_NO_SPACE:
			case SnapshotLocationStatus.HAS_SNAPSHOTS_HAS_SPACE:
				infobar_location.hide();
				break;
			}
		}
		else{
			switch (status_code){
				case SnapshotLocationStatus.NOT_SELECTED:
					lbl_infobar_location.label = "<span weight=\"bold\">%s</span>".printf(details);
					infobar_location.message_type = Gtk.MessageType.ERROR;
					infobar_location.no_show_all = false;
					infobar_location.show_all();
					ok = false;
					break;

				case SnapshotLocationStatus.NOT_AVAILABLE:
				case SnapshotLocationStatus.HAS_SNAPSHOTS_NO_SPACE:
				case SnapshotLocationStatus.NO_SNAPSHOTS_NO_SPACE:
					lbl_infobar_location.label = "<span weight=\"bold\">%s</span>".printf(
						message.replace("<","&lt;"));
					infobar_location.message_type = Gtk.MessageType.ERROR;
					infobar_location.no_show_all = false;
					infobar_location.show_all();
					ok = false;
					break;

				case SnapshotLocationStatus.READ_ONLY_FS:
				case SnapshotLocationStatus.HARDLINKS_NOT_SUPPORTED:
					lbl_infobar_location.label = "<span weight=\"bold\">%s</span>".printf(message);
					infobar_location.message_type = Gtk.MessageType.ERROR;
					infobar_location.no_show_all = false;
					infobar_location.show_all();
					ok = false;
					break;

				case SnapshotLocationStatus.NO_BTRFS_SYSTEM:
					lbl_infobar_location.label = "<span weight=\"bold\">%s</span>".printf(details);
					infobar_location.message_type = Gtk.MessageType.ERROR;
					infobar_location.no_show_all = false;
					infobar_location.show_all();
					ok = false;
					break;

				case 3:
				case 0:
					infobar_location.hide();
					// TODO: Show a disk icon with stats when selected device is OK
					break;
			}

		}

		return ok;
	}

	private void tv_datasets_refresh(){

		App.update_datasets();

		var model = new Gtk.TreeStore(4,
			typeof(Zvol),
			typeof(string),
			typeof(string),
			typeof(bool));

		zfs_datasets.set_model (model);

		TreeIter iter0;

		foreach(var dataset in App.datasets) {

			model.append(out iter0, null);
			model.set(iter0, 0, dataset, -1);
			model.set(iter0, 1, dataset.tooltip_text(), -1);
			model.set(iter0, 2, IconManager.ICON_HARDDRIVE, -1);
			model.set(iter0, 3, false, -1);

//			tv_append_child_volumes(ref model, ref iter0, disk);
		}

//		tv_devices.expand_all();
//		tv_devices.columns_autosize();
	}
}
