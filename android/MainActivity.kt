package com.example.budgetingapp

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class MainActivity : AppCompatActivity() {

    private lateinit var goalInput: EditText
    private lateinit var savingsInput: EditText
    private lateinit var resultText: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        goalInput = findViewById(R.id.goal_input)
        savingsInput = findViewById(R.id.savings_input)
        resultText = findViewById(R.id.result_text)
        val calculateButton: Button = findViewById(R.id.calculate_button)
        val notifyButton: Button = findViewById(R.id.notify_button)

        calculateButton.setOnClickListener {
            calculateRemaining()
        }

        notifyButton.setOnClickListener {
            scheduleWeeklyNotification()
        }

        createNotificationChannel()
    }

    private fun calculateRemaining() {
        val goal = goalInput.text.toString().toDoubleOrNull() ?: 0.0
        val savings = savingsInput.text.toString().toDoubleOrNull() ?: 0.0
        val remaining = (goal - savings).coerceAtLeast(0.0)
        resultText.text = "You need to save: \$${String.format("%.2f", remaining)}"
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "budgeting_channel",
                "Budgeting Notifications",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Channel for budgeting reminders"
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun scheduleWeeklyNotification() {
        val notification = NotificationCompat.Builder(this, "budgeting_channel")
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("Budgeting Reminder")
            .setContentText("Don't forget to save for your goal this week!")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        with(NotificationManagerCompat.from(this)) {
            notify(1, notification)
        }
    }
}
