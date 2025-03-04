using System;
using System.Windows;
using System.Windows.Forms;

namespace BudgetingApp
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
        }

        private void CalculateButton_Click(object sender, RoutedEventArgs e)
        {
            double goalAmount = 0;
            double currentSavings = 0;

            double.TryParse(GoalAmountInput.Text, out goalAmount);
            double.TryParse(CurrentSavingsInput.Text, out currentSavings);

            double remainingAmount = Math.Max(0, goalAmount - currentSavings);
            ResultText.Text = $"You need to save: ${remainingAmount:F2}";
        }

        private void EnableNotificationsButton_Click(object sender, RoutedEventArgs e)
        {
            System.Windows.MessageBox.Show("Weekly notifications are not implemented yet. You'll receive reminders soon!");
        }
    }
}
