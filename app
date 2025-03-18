from flask import Flask, request, jsonify
import stripe
import uuid
from flask_mail import Mail, Message

app = Flask(__name__)

# Configure Flask-Mail
app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 587
app.config['MAIL_USE_TLS'] = True
app.config['MAIL_USERNAME'] = 'your-email@gmail.com'
app.config['MAIL_PASSWORD'] = 'your-email-password'
mail = Mail(app)

# Stripe secret key (replace with your key)
stripe.api_key = 'your-stripe-secret-key'

# Dummy event data for simplicity
event_data = {
    'name': 'Concert',
    'date': '2025-04-20',
    'time': '7:00 PM',
    'seat': 'A12',
    'price': 100,  # In USD
}

@app.route('/book', methods=['POST'])
def book_event():
    data = request.get_json()
    payment_method_id = data['paymentMethodId']
    user_email = data['userEmail']

    try:
        # 1. Process the payment via Stripe
        payment_intent = stripe.PaymentIntent.create(
            amount=event_data['price'] * 100,  # Convert to cents
            currency='usd',
            payment_method=payment_method_id,
            confirm=True,
        )

        if payment_intent.status == 'succeeded':
            # 2. Generate unique booking reference
            booking_reference = str(uuid.uuid4())

            booking_details = {
                'event': event_data['name'],
                'date': event_data['date'],
                'time': event_data['time'],
                'seat': event_data['seat'],
                'totalPrice': event_data['price'],
                'reference': booking_reference
            }

            # 3. Send booking confirmation email
            msg = Message(
                'Booking Confirmation',
                sender='your-email@gmail.com',
                recipients=[user_email]
            )
            msg.body = f"""
            Thank you for your booking!

            Event: {booking_details['event']}
            Date: {booking_details['date']}
            Time: {booking_details['time']}
            Seat: {booking_details['seat']}
            Total Price: ${booking_details['totalPrice']}

            Your booking reference number is: {booking_details['reference']}
            """
            mail.send(msg)

            return jsonify({
                'message': 'Booking confirmed',
                'bookingReference': booking_reference,
                'bookingDetails': booking_details
            }), 200

        else:
            return jsonify({'message': 'Payment failed'}), 400

    except Exception as e:
        return jsonify({'message': f'An error occurred: {str(e)}'}), 500


if __name__ == '__main__':
    app.run(debug=True)
