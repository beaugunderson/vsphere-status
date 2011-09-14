var grid;
var ordered_data = [];

var columns = [
   { id: "name", name: "Name", field: "name", width: 240, sortable: true },
   { id: "host", name: "Host", field: "host", width: 200, sortable: true },
   { id: "guestName", name: "Guest Name", field: "guestName", width: 320, sortable: true },
   { id: "powerState", name: "Power State", field: "powerState", width: 120, sortable: true },
   { id: "cpuUsage", name: "CPU Usage", field: "cpuUsage", width: 100, sortable: true, sorter: numericComparer },
   { id: "guestMemoryUsage", name: "Mem. Usage", field: "guestMemoryUsage", width: 100, sortable: true, sorter: numericComparer }
];

function classForRow(item) {
   if (item.powerState != 'poweredOn') {
      return 'dim';
   }

   return '';
}

var options = {
   editable: false,
   enableAddRow: false,
   enableCellNavigation: false,
   rowCssClasses: classForRow
};

function processFolder(folder) {
   _.each(folder.entries, function(i) {
      ordered_data.push(i);
   });

   _.each(folder.folders, function(i) {
      processFolder(i);
   });
}

var sortdir;
var sortcol;

function comparer(a, b) {
   var x = a[sortcol];
   var y = b[sortcol];

   return sortdir * (x == y ? 0 : (x > y ? 1 : -1));
}

function numericComparer(a, b) {
   var x = parseInt(a[sortcol], 10);
   var y = parseInt(b[sortcol], 10);

   return sortdir * (x == y ? 0 : (x > y ? 1 : -1));
}

$(function() {
   $.getJSON("vsphere_json.pl", function(data) {
      _.each(data, function(i) {
         processFolder(i);
      });

      $("#loading").hide();

      grid = new Slick.Grid("#result-grid", ordered_data, columns, options);

      grid.onSort.subscribe(function(e, args) {
         sortdir = args.sortAsc ? 1 : -1;
         sortcol = args.sortCol.field;

         if (args.sortCol.sorter) {
            ordered_data.sort(args.sortCol.sorter);
         } else {
            ordered_data.sort(comparer);
         }

         grid.invalidateAllRows();
         grid.render();
      });
   });
});
